from brownie import GutterCatChicks, accounts


def main():
    owner = accounts[0]
    # Deploy mocks
    # Deploy chicks SC
    chicks = GutterCatChicks.deploy(
        {"from": owner},
    )
    whitelisted_addresses = []
    for i in range(0, 300):
        whitelisted_addresses.append(accounts[1].address)
    print(len(whitelisted_addresses))
    chicks.whitelistAddresses(whitelisted_addresses)
