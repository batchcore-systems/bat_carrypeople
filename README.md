<meta name="description" content="Modern FiveM Carry resource with three carry types, optional UI, ESX/QBCore/ox support, target integration, and admin carry mode. CarryPeople" />

# bat_carrypeople
![](https://img.shields.io/github/downloads/batchcore-systems/bat_carrypeople/total?logo=github)
![](https://img.shields.io/github/downloads/batchcore-systems/bat_carrypeople/latest/total?logo=github)
![](https://img.shields.io/github/contributors/batchcore-systems/bat_carrypeople?logo=github)

Simple and modern FiveM carry resource with config and good compatibility.

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
git clone https://github.com/mattibat/bat_carrypeople.git
```
Or simply click here: [Download Latest Version](https://github.com/mattibat/bat_carrypeople/archive/refs/heads/main.zip)

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
- Well performing on Servers with high player count

## Works with

- ESX
- QBCore
- OX
- Standalone

## Need help?

Contact us on [Discord](https://discord.gg/exrdXVuAWz)

## Contributions

Contributions are welcome.

---

Made with ♥️ by Batchcore Systems
