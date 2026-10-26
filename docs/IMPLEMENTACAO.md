# Implementação dos ajustes do boletim

Versão preparada: 0.1.0. Repositório: AlertaDengue/infodengue_intramunicipal.
Os PRs são encadeados, estão em rascunho e devem ser incorporados na ordem abaixo.
Nenhum merge ou publicação de versão foi feito automaticamente.

| Etapa | PR | Entrega |
| --- | --- | --- |
| 01 | [#3](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/3) | Dependências e carregamento sem instalação automática |
| 02 | [#4](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/4) | Acentos e locale C |
| 03 | [#5](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/5) | SE 53, semanas consecutivas e avisos de exclusão |
| 04 | [#6](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/6) | Entradas exportadas e caso sintético de Feira Livre |
| 05 | [#7](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/7) | Diagnóstico de Quarto/LaTeX |
| 06 | [#8](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/8) | Gerador v2, parâmetros e logos opcionais |
| 07 | [#9](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/9) | Gráficos explícitos e APIs antigas obsoletas |
| 08 | [#10](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/10) | Painel de mapas adaptável |
| 09 | [#11](https://github.com/AlertaDengue/infodengue_intramunicipal/pull/11) | Novo boletim, agravos condicionais e integração |
| 10 | Branch `codex/10-documentacao-publicacao` | README, migração, documentação e preparação da versão |

## Verificações realizadas

- Instalação do pacote em biblioteca separada com `R CMD INSTALL`.
- Testes do pacote: 166 verificações passaram, sem falhas ou skips. A suíte emite
  12 avisos, decorrentes de chamadas intencionais às APIs obsoletas e de um teste
  de coluna opcional ausente.
- `R CMD build` e `R CMD check --no-manual`, com sugestões não obrigatórias:
  sem erros ou WARNINGs, com quatro NOTEs descritas abaixo.
- `git diff --check` sem erros.
- Migração de strings R para escapes Unicode: igualdade das expressões obtidas
  por `parse(..., keep.source = FALSE)` verificada antes/depois, preservando valores.
- Geração e execução do boletim com dengue, dengue + chikungunya, chikungunya
  isolada, ausência de notificações, chikungunya somente no histórico anterior e
  ano de referência 2025 com dados de 2026 disponíveis.
- PDFs compilados por Quarto/XeLaTeX: dengue sem logos (13 páginas), com logos
  de demonstração, período vazio e dengue + chikungunya (19 páginas). Texto dos PDFs
  conferido sem referências pendentes; ausência da seção de chikungunya no caso
  original confirmada. Páginas de mapas, curvas e Rt inspecionadas visualmente.
- Nowcasting solicitado com INLA e uma thread: ajuste municipal e dos quatro
  distritos concluídos. Uma execução sob restrições de acesso ao sistema também
  verificou que a falha fica identificada no relatório, sem produzir falsa estimativa.

Ambiente principal: R 4.4.3, ggplot2 4.0.2, sf 1.1.0, AlertTools 1.1.0 e Quarto 1.5.57,
em macOS. Não foi feita validação em Windows ou Linux nesta execução. Os testes
com executável controlado pulam Windows por usarem um script de shell.

## Evidência de Feira Livre

Os arquivos originais são sintéticos e foram preservados. O fluxo original de dengue
produziu 7.210 notificações brutas, 6.921 alocadas e 6.921 conservadas na grade;
289 não foram alocadas. A referência contém 28 bairros e quatro distritos, somando
249.990 habitantes. O denominador municipal informado no exemplo é 250.000.

A janela final contém SE 35, 36 e 37 de 2026, incluindo a semana sem notificações.
As oito notificações informadas em 202553 deixaram de desaparecer na grade.
O histórico municipal tem 24 casos nessa mesma semana e não foi alterado para
igualá-lo às notificações. Há 143 divergências entre datas e códigos epidemiológicos
no conjunto original; o relatório as informa e preserva os códigos fornecidos.

O caso derivado com os dois agravos conserva 14.420 notificações brutas e 13.842
alocadas na grade. O recorte de 2025 conserva 3.294 brutas e 3.160 alocadas;
a janela final inclui a SE 53. Os cenários derivados são exclusivamente testes,
não representam dados reais de chikungunya.

## NOTEs do verificador

As quatro NOTEs não são erros ou WARNINGs de compilação:

1. Tamanho dos dados legados já distribuídos no pacote: cerca de 5 MB no diretório
   `data`, dentro de aproximadamente 6 MB instalados.
2. Dependências usadas pelos templates Quarto, declaradas em `Imports`, que o
   verificador estático de código R não identifica como chamadas de `R/`.
3. Símbolos usados em avaliação não padrão e dependências de globais nas APIs
   legadas mantidas por compatibilidade. Os gráficos do novo template usam APIs explícitas.
4. Strings UTF-8 presentes nos conjuntos de dados legados. As strings executáveis
   dos arquivos R passaram pela checagem de portabilidade.

Os avisos iniciais de documentação de dados/argumentos e de strings não ASCII
no código R foram corrigidos antes da preparação final. A versão foi preparada
para revisão; não houve publicação no CRAN ou criação de release no GitHub.

## Reprodução

Instale o pacote e execute, no checkout:

```sh
Rscript tools/verificar_boletim.R /tmp/feira-livre dengue validar
Rscript tools/verificar_boletim.R /tmp/feira-livre-misto misto validar
Rscript tools/verificar_boletim.R /tmp/feira-livre-vazio vazio validar
Rscript tools/verificar_boletim.R /tmp/feira-livre-historico chikon-historico validar
Rscript tools/verificar_boletim.R /tmp/feira-livre-2025 ano-2025 validar
Rscript tools/verificar_boletim.R /tmp/feira-livre-pdf dengue pdf
```

O cenário `nowcasting` solicita INLA. O padrão é não ajustar nowcasting. Os limiares
5, 50 e 10 e a UF XX usados nos roteiros são demonstrativos; devem ser substituídos
pelos parâmetros apropriados antes de produzir um boletim real.

QMDs antigos precisam ser regenerados para receber o novo template. Os arquivos
recebidos como `criar_qmd_boletim_v2.R` e `boletim_municipal_completo_att.qmd`
foram integrados aos nomes canônicos do pacote; nenhum boletim depende de Downloads.
