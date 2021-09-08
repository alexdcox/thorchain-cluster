# Thorchain Local Cluster

Setup all the Thorchain essentials for a local regression test cluster, including a handful of connected chains:
- bitcoin
- binance
- dash

Reasons for this repo:
- To help me understand the setup process.
- To serve as a record of my progress. 
- To make it easier to ask for help.
- To serve as an educational aid - with every step logged for transparency.
- To provide an easy, fast, offline way to run a private net with IDE debugging capability.

## Requirements

- My custom image for Thorchain: `github.com/alexdcox/thornode:mocknet`.
- My custom image for dash: `github.com/alexdcox/dash:latest`.

## Running

```
chmod +x ./thornode.sh
./thornode.sh
```