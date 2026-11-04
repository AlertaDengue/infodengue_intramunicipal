# infodengueintramunicipal 0.1.1

- Renomeia o pacote para infodengueintramunicipal (nomes R não aceitam sublinhados).
- Inclui o logo oficial do InfoDengue sempre à esquerda; somente logo_direita é configurável.
- Usa nowcasting_mgcv() do nowcaster >= 1.0.1, sem necessidade de INLA, e documenta a instalação pelo GitHub.
- Simplifica a chamada do gerador no README e documenta a migração.

# infodengueintramunicipal 0.1.0

* Integra gerador v2 e novo boletim municipal, com dados sintéticos de Feira Livre.
* Corrige nomes acentuados em locale C e preserva a SE 53 nas funções de completude.
* Exporta funções de leitura/validação e documenta estimativas ausentes sem fabricar dados.
* Declara dependências e impede instalação de pacotes R durante a renderização.
* Preserva diagnóstico de falhas de Quarto/LaTeX.
* Exige limiares municipais explícitos; acrescenta rótulos no singular/plural,
  logos PNG opcionais, caminhos absolutos e proteção contra sobrescrita.
* Migra os gráficos do template para APIs sem globais; funções antigas são obsoletas.
* Compõe quantidade variável de mapas com legenda compartilhada e trata CRS locais.
* Omite seções sem agravos no recorte, resolve referências automaticamente e informa
  ausência de notificações; nowcasting opcional comunica seu estado e suas falhas.

## Migração

Regere QMDs antigos para receber as mudanças e informe limiares próprios do município.
Mapas agora exibem todos os elementos da lista; selecione previamente o subconjunto desejado.
A ausência de casos_est aparece como informação indisponível, sem copiar casos observados.
