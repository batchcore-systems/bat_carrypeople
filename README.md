<meta name="description" content="Modern FiveM Carry resource with three carry types, optional UI, ESX/QBCore/ox support, target integration, and admin carry mode. FiveM CarryPeople" />

# bat_carrypeople
![](https://img.shields.io/github/downloads/batchcore-systems/bat_carrypeople/total?logo=github)
![](https://img.shields.io/github/downloads/batchcore-systems/bat_carrypeople/latest/total?logo=github)
![](https://img.shields.io/github/contributors/batchcore-systems/bat_carrypeople?logo=github)

batchcore systems CarryPeople is a new carry system that combines simplicity and high functionality with performance and compatibility. It has many settings and support for well-known frameworks such as ESX, QBcore, OX and standalone

## Showcase Video
https://streamable.com/z42ivr

## What it does

Players can carry nearby players with multiple carry styles and optional UI/target flow.

- 3 carry types (toggle each one in config)
- Optional UI picker and type command
- Optional ox_target / qb-target support
- Admin carry mode with locked uncarry behavior
- Works efficiently on live servers

## How to install

1. Clone into your resources folder:
```bash
git clone https://github.com/batchcore-systems/bat_carrypeople.git
```
Or simply click here: [Download Latest Version](https://github.com/batchcore-systems/bat_carrypeople/archive/refs/heads/main.zip)

2. Add to your server.cfg:
```cfg
ensure bat_carrypeople
```

3. Restart server or run `refresh` and `ensure bat_carrypeople` in your live console.

## Commands

- `/carry`
- `/carry type (1|2|3)` - `/carry (1|2|3)`
- `/uncarry` (if alias is enabled)
- `/carryadmin [1|2|3]` (default is 1)

## Performance

- Designed for low overhead in normal RP usage
- Well performing on Servers with high player counts

## Works with

- ESX
- QBCore
- OX
- Standalone

## Need help?

Contact us on [Discord](https://discord.gg/exrdXVuAWz)

## Contributions

Contributions are welcome. Just fork our github Repository, and open a pull request.

---

Made with ♥️ by Batchcore Systems
