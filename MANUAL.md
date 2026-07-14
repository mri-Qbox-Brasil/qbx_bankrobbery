# qbx_bankrobbery — Manual

Assalto a bancos: seis Fleeca (hack), Paleto e Pacific Standard (cartão de segurança + termite), mais 13 subestações de energia que derrubam câmeras e podem causar blackout na cidade.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Itens necessários](#itens-necessários)
4. [Configuração](#configuração)
5. [Fluxo do assalto](#fluxo-do-assalto)
6. [Subestações e blackout](#subestações-e-blackout)
7. [Recompensas](#recompensas)
8. [Integrações](#integrações)
9. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
10. [Localização](#localização)
11. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qbx_core` | Sim | `GetPlayer`, itens usáveis, notificações, `playerdata`, `lib` |
| `ox_lib` | Sim | Zonas, progress bar, callbacks, locale |
| `ox_inventory` | Sim | `Search`, `AddItem`, `RemoveItem` |
| `ox_doorlock` | Sim | `setDoorState` nas portas abertas com termite |
| `mhacking` | Sim | Minigame de hack das Fleeca e do Pacific |
| `qb-weathersync` | Sim | `setBlackout` quando todas as subestações caem |
| `ox_target` | Não | Só quando `useTarget = true` |
| `ps-evidence` / `qb-policejob` | Não | Digitais (`evidence:server:CreateFingerDrop`) |
| `qb-banking` | Não | Fecha o banco durante o assalto (`qb-banking:server:SetBankClosed`) |
| `qb-scoreboard` | Não | Marca a atividade como ocupada |
| `qb-hud` | Não | Estresse ao furar cofre (`hud:server:GainStress`) |

O alerta policial usa o evento `police:server:policeAlert` e a contagem de policiais vem do evento `police:SetCopCount`.

---

## Instalação

1. Copie a pasta `qbx_bankrobbery` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure qbx_bankrobbery
   ```
3. Cadastre os itens no `ox_inventory` (ver abaixo). Não há SQL.
4. Cadastre no `ox_doorlock` as portas internas abertas com termite. Os `doorId` referenciados no `config/shared.lua` são: `5` (Paleto) e `2` e `3` (Pacific). Ajuste esses IDs para os do seu `ox_doorlock`.

**Conflitos** — substitui o `qb-bankrobbery`. Não rode os dois juntos.

---

## Itens necessários

Todos precisam existir no `ox_inventory`.

| Item | Papel |
|---|---|
| `electronickit` | Item usável. Inicia o hack da Fleeca e do Pacific |
| `trojan_usb` | Consumido junto com o `electronickit` no hack |
| `thermite` | Item usável. Abre o minigame de termite nas subestações e nas portas internas |
| `lighter` | Precisa estar no inventário para acender a termite |
| `drill` | Necessário para furar os cofres de Paleto e Pacific |
| `security_card_01` | Item usável. Abre o cofre de Paleto |
| `security_card_02` | Item usável. Abre o cofre do Pacific |
| `black_money` | Recompensa em dinheiro sujo |
| `goldchain`, `rolex`, `goldbar` | Recompensas de item dos cofres |
| `weapon_stungun`, `weapon_vintagepistol`, `weapon_microsmg`, `weapon_minismg` | Recompensas raras dos cofres |

---

## Configuração

### `config/client.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `useTarget` | bool | Sim | `true` usa `ox_target` nos cofres; `false` usa zonas com tecla `E`. Padrão: `false` |
| `debugPoly` | bool | Sim | Desenha as zonas em debug |
| `fingerprintChance` | number | Sim | Chance (%) de deixar digital ao abrir um cofre sem luvas. Padrão: `50` |
| `minPaletoPolice` | number | Sim | Mínimo de policiais online para assaltar Paleto. Padrão: `0` |
| `minPacificPolice` | number | Sim | Mínimo de policiais online para assaltar o Pacific. Padrão: `0` |
| `minFleecaPolice` | number | Sim | Mínimo de policiais online para assaltar uma Fleeca. Padrão: `0` |
| `minThermitePolice` | number | Sim | Mínimo de policiais online para usar termite. Padrão: `0` |
| `outlawCooldown` | number | Sim | Minutos até a polícia poder ser chamada de novo pelo mesmo alarme. Padrão: `5` |

### `config/shared.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `powerStations` | table | Sim | 13 subestações: `{ coords, hit }`. `hit` é o estado em runtime |
| `smallBanks` | table | Sim | As 6 Fleeca. Ver campos abaixo |
| `bigBanks.paleto` | table | Sim | Blaine County Savings Bank |
| `bigBanks.pacific` | table | Sim | Pacific Standard |

Campos de um banco:

| Campo | Tipo | Descrição |
|---|---|---|
| `label` | string | Nome exibido |
| `coords` | vec3 | Porta do cofre. No Pacific é uma tabela com dois pontos (`[1]` entrada, `[2]` porta do cofre) |
| `alarm` | bool | Se o alarme está armado. Vira `false` quando as câmeras do banco caem |
| `object` | hash | Modelo da porta do cofre |
| `heading` | table | `closed` e `open` — o heading da porta em cada estado |
| `camId` | number | ID da câmera do banco, usado no mapeamento de `cameraHits` |
| `isOpened` | bool | Estado em runtime |
| `lockers` | table | Cofres individuais: `{ coords, isBusy, isOpened }`. Fleeca e Paleto têm 8; Pacific tem 10 |
| `thermite` | table | Só nos bancos grandes. Portas internas: `{ coords, isOpened, doorId }` — `doorId` é o ID no `ox_doorlock` |

### `config/server.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `hitsNeeded` | number | Sim | Quantas subestações precisam cair para causar blackout. Padrão: `13` (todas) |
| `blackoutTimer` | number | Sim | Duração do blackout em minutos. Padrão: `10` |
| `rewardTypes` | table | Sim | Tipos de recompensa sorteados: `item` e `money` |
| `lockerRewards` | table | Sim | Recompensas das Fleeca, por tier (`tier1`..`tier3`): `{ item, minAmount, maxAmount }` |
| `lockerRewardsPaleto` | table | Sim | Recompensas de Paleto, por tier |
| `lockerRewardsPacific` | table | Sim | Recompensas do Pacific, por tier |
| `cameraHits` | table | Sim | Mapeia cada câmera (`camId`) às subestações que precisam cair para derrubá-la. `type` é `police`, `bank` ou ambos |

---

## Fluxo do assalto

### Fleeca (bancos pequenos)

1. O jogador usa o `electronickit` dentro da zona do banco, com um `trojan_usb` no inventário.
2. Validações: nenhum outro assalto ativo no servidor, policiais online suficientes (`minFleecaPolice`), banco ainda fechado.
3. Barra de progresso de 7,5s → os dois itens são consumidos e o minigame `mhacking` abre.
4. Se o alarme estiver armado, a polícia é chamada (com blip piscante) e entra em cooldown de `outlawCooldown` minutos.
5. Com o hack concluído, a porta do cofre abre. Cada locker leva 20 segundos de arrombamento (sem drill).
6. Depois de **30 minutos**, o banco reseta: porta e lockers voltam ao estado inicial.

### Paleto e Pacific

1. O jogador usa `security_card_01` (Paleto) ou `security_card_02` (Pacific) na porta do cofre. O Pacific também aceita o hack com `electronickit` + `trojan_usb`.
2. As portas internas (`thermite`) são abertas com o item `thermite` (requer `lighter`), via minigame de termite na NUI. Isso destranca a porta correspondente no `ox_doorlock`.
3. Cada locker exige o item `drill` e uma barra de progresso de 20 segundos com o prop da furadeira. Sem o drill, o cofre é "forte demais".
4. Furar um cofre gera estresse (`hud:server:GainStress`, 4 a 8 a cada 10 segundos) e pode deixar digital se o jogador não estiver de luvas.
5. Depois de **90 minutos**, os dois bancos grandes resetam.

Enquanto um assalto está em andamento, `robberyBusy` fica `true` no servidor e **nenhum outro banco pode ser aberto**.

O servidor valida a distância (2,5 metros) em cada evento de abrir banco, abrir locker e receber item — trigger remoto fora da posição é rejeitado com erro no console.

---

## Subestações e blackout

As 13 subestações são abertas com **termite** (item `thermite` + `lighter`), via minigame na NUI. Cada uma que cai:

- Desliga as câmeras mapeadas em `cameraHits` — tanto de delegacia (`police:client:SetCamera`) quanto de banco (`qbx_bankrobbery:client:BankSecurity`).
- Uma câmera de banco derrubada **desarma o alarme** daquele banco: o assalto deixa de chamar a polícia automaticamente.

Quando `hitsNeeded` subestações estiverem derrubadas (13 por padrão, ou seja, todas):

- `qb-weathersync` entra em blackout.
- Todas as câmeras de banco e de polícia são desativadas.
- Após `blackoutTimer` minutos (10 por padrão), a energia e as câmeras voltam.

Usar termite sempre deixa digital: a chance é de 85% mesmo com luvas, e 100% sem elas.

---

## Recompensas

Cada locker sorteia um tipo (`item` ou `money`) e um tier. As faixas de tier variam por banco:

| Banco | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---|---|---|---|
| Fleeca | < 50 | 50–79 | 80–94 | 95+ (`security_card_01`) |
| Paleto | < 25 | 25–69 | 70–94 | 95+ (`security_card_02`) |
| Pacific | < 10 | 25–49 | 50–94 | 95+ (dinheiro sujo) |

Recompensa em dinheiro: `black_money` de 20.000 a 30.000 (Fleeca) ou de 10.000 a 40.000 (Paleto e Pacific).

Recompensa em item: sorteada de `lockerRewards*` do tier correspondente. Por padrão `goldchain` (tier 1), `rolex` (tier 2) e `goldbar` (tier 3); no Pacific, `goldbar` em todos os tiers.

Há também uma chance pequena de sair arma no lugar da recompensa: `weapon_stungun` (Fleeca), `weapon_vintagepistol` (Paleto), `weapon_microsmg` ou `weapon_minismg` (Pacific).

---

## Integrações

### ox_doorlock

As portas internas dos bancos grandes abertas com termite são destrancadas via `exports.ox_doorlock:setDoorState(doorId, false)`. Os `doorId` do config precisam corresponder aos IDs cadastrados no `ox_doorlock`.

### qb-banking

Ao iniciar o assalto de uma Fleeca, o recurso dispara `qb-banking:server:SetBankClosed` para fechar aquele banco enquanto o roubo estiver ativo, reabrindo no reset.

### qb-scoreboard

O estado do assalto é publicado em `qb-scoreboard:server:SetActivityBusy`, com o nome `bankrobbery` (Fleeca), `paleto` ou `pacific`.

### mhacking

O minigame das Fleeca e do Pacific usa `mhacking:show` / `mhacking:start`, com 6 a 7 blocos e 15 a 30 segundos.

### Evidências

Digitais são criadas via `evidence:server:CreateFingerDrop`. O recurso checa luvas com `qbx.isWearingGloves()`.

---

## Entrypoints para outros recursos

### Callback `qbx_bankrobbery:server:isRobberyActive`

Retorna `true` se existe um assalto em andamento no servidor.

```lua
local busy = lib.callback.await('qbx_bankrobbery:server:isRobberyActive', false)
```

### Callback `qbx_bankrobbery:server:GetConfig`

Retorna, nesta ordem, `powerStations`, `bigBanks` e `smallBanks` com o estado atual.

```lua
local stations, bigBanks, smallBanks = lib.callback.await('qbx_bankrobbery:server:GetConfig', false)
```

### Evento `qbx_bankrobbery:server:SetStationStatus`

Marca uma subestação como derrubada (ou restaurada). Dispara a checagem de câmeras e blackout.

```lua
TriggerServerEvent('qbx_bankrobbery:server:SetStationStatus', stationId, true)
```

### Evento `qbx_bankrobbery:server:callCops`

Dispara o alerta de assalto. `type` é `small`, `paleto` ou `pacific`. Só funciona se o alarme do banco estiver armado.

```lua
TriggerServerEvent('qbx_bankrobbery:server:callCops', 'small', bankId, coords)
```

### Eventos de câmera

O recurso emite estes eventos para o sistema de câmeras da polícia:

```lua
TriggerClientEvent('police:client:SetCamera', -1, cameraIds, false)
TriggerClientEvent('police:client:DisableAllCameras', -1)
TriggerClientEvent('police:client:EnableAllCameras', -1)
```

### Evento `qbx_bankrobbery:client:BankSecurity`

Liga/desliga o alarme dos bancos indicados.

```lua
TriggerClientEvent('qbx_bankrobbery:client:BankSecurity', -1, { 1, 2 }, false)
```

---

## Localização

Strings via `ox_lib` locale, em `locales/`:

`da`, `de`, `en`, `es`, `fr`, `nl`, `pt`, `pt-br`

Idioma ativo definido no `server.cfg`:

```
setr ox:locale "pt-br"
```

---

## Estrutura de arquivos

```
qbx_bankrobbery/
├── client/
│   ├── main.lua           — estado dos bancos, abertura de lockers, digitais, alerta policial
│   ├── fleeca.lua         — hack e zonas das 6 Fleeca
│   ├── paleto.lua         — cartão de segurança, zonas e cofres de Paleto
│   ├── pacific.lua        — cartão/hack, zonas e cofres do Pacific Standard
│   ├── powerstation.lua   — termite nas subestações, NUI, incêndios
│   └── doors.lua          — posição e heading das portas de cofre, reset
├── server/
│   └── main.lua           — estado global, recompensas, timeouts, blackout, itens usáveis
├── config/
│   ├── client.lua         — useTarget, chances, mínimos de polícia, cooldown
│   ├── server.lua         — recompensas por tier, blackout, mapa de câmeras
│   └── shared.lua         — subestações, Fleeca, Paleto e Pacific
├── html/
│   ├── index.html         — minigame de termite
│   ├── script.js
│   ├── style.css
│   └── reset.css
├── locales/
│   └── *.json             — traduções (8 idiomas)
└── fxmanifest.lua
```
