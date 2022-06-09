from brownie import GutterCatChicks, Cats, Dogs, Rats, Pigeons, Clones, accounts


def main():
    owner = accounts[0]
    # Deploy mocks
    # Deploy chicks SC
    chicks = GutterCatChicks.deploy(
        {"from": owner},
    )
