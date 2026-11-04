# Plano de implementação — issue #16

Issue: https://github.com/AlertaDengue/infodengue_intramunicipal/issues/16

Objetivo: permitir que o boletim utilize o modelo climático e os limiares definidos para cada município, mantendo consistência entre entradas, alertas submunicipais, gráficos e textos.

## 1. Definir a configuração climática

Adicionar um argumento `config_climatica` a `criar_qmd_boletim()`, contendo:

- Código do modelo do AlertTools.
- Nomes das colunas climáticas no histórico.
- Limiar de cada variável utilizada.

Suportar os modelos existentes: temperatura mínima, umidade máxima, umidade mínima e combinações de temperatura com umidade.

Os parâmetros serão fornecidos pelo usuário a partir da configuração oficial municipal. O pacote não tentará deduzi-los pelo município nem estimá-los automaticamente.

Para compatibilidade, a ausência dessa configuração manterá temporariamente o comportamento legado, com aviso explícito de que temperatura mínima e 18 °C precisam ser confirmados para o município.

## 2. Centralizar a validação

Criar uma função interna que valide e normalize essa configuração antes de gerar o boletim.

Ela deverá verificar:

- Modelo reconhecido e variáveis compatíveis.
- Limiares numéricos finitos, com umidade entre 0 e 100%.
- Presença e conteúdo das colunas necessárias.
- Ausência de configurações contraditórias.

Colunas obrigatórias ausentes impedirão a execução. Valores climáticos ausentes em semanas específicas serão identificados como indisponíveis, com tratamento explícito no cálculo e na apresentação. Não haverá substituição silenciosa por outra variável.

## 3. Adaptar a preparação dos dados e os alertas

Alterar `preparar_historico_alerta()` para exigir as variáveis selecionadas, em vez de exigir sempre `tempmin`.

No template:

- Remover o modelo `Af` e o limiar 18 fixos.
- Transportar as variáveis climáticas necessárias para as séries dos agrupamentos.
- Construir os parâmetros do AlertTools a partir da configuração validada.
- Preservar os níveis municipais recebidos no histórico.
- Manter os limiares climáticos separados dos limiares de incidência.

O uso de parâmetros municipais nos agrupamentos será documentado como uma escolha do boletim, sem afirmar que houve calibração específica para cada distrito.

## 4. Atualizar gráficos e textos

Adaptar `create_receptivity_plot_novo()` e seu alias em português para receber a mesma configuração.

O gráfico deverá:

- Mostrar somente as variáveis selecionadas.
- Usar painéis separados para temperatura e umidade quando ambas forem necessárias.
- Exibir os limiares e as unidades corretas.
- Representar a condição climática conjunta exigida pelo modelo.
- Distinguir semanas sem informação de semanas desfavoráveis.

Remover referências fixas a 18 °C das legendas e dos textos. Alinhar os operadores de comparação com as regras do AlertTools.

A condição climática será apresentada separadamente do indicador de alerta, que também pode considerar casos e persistência temporal.

## 5. Validar o comportamento

Adicionar testes para:

- Os cinco modelos climáticos suportados.
- Valores abaixo, acima e exatamente nos limiares.
- Combinações em que apenas uma variável é favorável.
- Colunas ausentes, valores inválidos e semanas com dados incompletos.
- Compatibilidade do comportamento legado e emissão do aviso.
- Preservação dos níveis municipais fornecidos.

Criar cenários sintéticos reproduzíveis para temperatura apenas, umidade apenas e temperatura com umidade. Conferir os resultados contra as regras do AlertTools e gerar PDFs para inspeção visual.

Os parâmetros reais dos municípios citados na issue deverão ser confirmados antes de afirmar equivalência com seus boletins oficiais.

## 6. Documentar e entregar

Atualizar README, documentação das funções e notas da versão com:

- Estrutura da configuração e exemplos dos três cenários.
- Requisitos de entrada por modelo.
- Política para dados ausentes.
- Possíveis mudanças nos alertas submunicipais.
- Necessidade de regenerar boletins antigos.

Entregar em um PR vinculado à issue #16. Manter a issue aberta até revisar a implementação e suas evidências de validação.

## Critério de conclusão

O boletim deve aplicar a configuração escolhida sem recorrer silenciosamente a temperatura mínima, representar corretamente os critérios no gráfico e nos textos, preservar os indicadores municipais de entrada e passar pelos testes e pela validação dos PDFs.
