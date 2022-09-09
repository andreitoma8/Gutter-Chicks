from brownie import GutterCatChicks, accounts, config


def main():
    owner = accounts.add(config["wallets"]["from_key"])
    # Deploy chicks SC
    chicks = GutterCatChicks.deploy(
        {"from": owner}, publish_source=True
    )
    whitelisted_addresses = []
    chicks.whitelistAddresses(whitelisted_addresses)
