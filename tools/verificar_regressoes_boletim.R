args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 2L) stop("Use: Rscript tools/verificar_regressoes_boletim.R pasta cenario")
out <- args[1]; scenario <- args[2]
if (!scenario %in% c('sem-digitacao', 'sem-alocacao', 'misto-sem-alocacao-chikon')) stop('Cenario invalido.')
base_scenario <- if (scenario == 'misto-sem-alocacao-chikon') 'misto' else 'dengue'
stopifnot(system2(file.path(R.home('bin'),'Rscript'), c('tools/verificar_boletim.R', shQuote(out), base_scenario, 'gerar')) == 0L)
library(infodengesubmunicipal)
p <- file.path(out,'notificacoes.rds'); d <- readRDS(p)
if(scenario=='sem-digitacao') d$dt_digita <- NA_character_
if(scenario=='sem-alocacao') {d$nm_bairro <- NA_character_; d$id_bairro <- NA_character_}
if(scenario=='misto-sem-alocacao-chikon') {
  chik <- d$cid10_codigo == 'A92.0'
  d$nm_bairro[chik] <- NA_character_; d$id_bairro[chik] <- NA_character_
}
saveRDS(d,p)
qmd <- file.path(out,'boletim.qmd'); e <- new.env(parent=globalenv())
e$params <- yaml::yaml.load(strsplit(paste(readLines(qmd),collapse='\n'),'---',fixed=TRUE)[[1]][2])$params
knitr::opts_knit$set(rmarkdown.pandoc.to='latex')
r <- tryCatch({withr::with_dir(out,knitr::knit(qmd,output='avaliacao.md',envir=e,quiet=TRUE)); list(ok=TRUE)},error=function(err) list(ok=FALSE,erro=conditionMessage(err)))
for(n in c('df_mun','df_mun_ok','df_bairros','mun_observados')) if(exists(n,e,inherits=FALSE)) r[[n]] <- nrow(get(n,e))
if(exists('mun_observados',e,inherits=FALSE)) r$casos_observados <- sum(e$mun_observados$total_Y)
jsonlite::write_json(r,file.path(out,'resultado.json'),auto_unbox=TRUE,pretty=TRUE)
cat(jsonlite::toJSON(r,auto_unbox=TRUE),'\n')

stopifnot(isTRUE(r$ok))
if (scenario == 'sem-digitacao') stopifnot(r$casos_observados == 7210L, nrow(e$mun_nowcast) == 0L)
if (scenario == 'sem-alocacao') {
  stopifnot(nrow(e$df_mun_ok) == 0L, nrow(e$df_bairros) > 0L,
            sum(e$df_bairros$notificações) == 0, all(is.na(e$df_distritos$nivel)),
            sum(e$perda_notificação$perca) == 7210L)
}
if (scenario == 'misto-sem-alocacao-chikon') {
  stopifnot(nrow(e$df_mun_ok) == 6921L, sum(e$df_bairros$notificações) == 6921L,
            all(is.na(e$df_distritos$nivel[e$df_distritos$arbo == 'chikon'])))
}
