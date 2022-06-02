from brownie import GutterCatChicks, Cats, Dogs, Rats, Pigeons, Clones, accounts


def main():
    owner = accounts[0]
    # Deploy mocks
    cats = Cats.deploy({"from": owner})
    dogs = Dogs.deploy({"from": owner})
    rats = Rats.deploy({"from": owner})
    pigeons = Pigeons.deploy({"from": owner})
    clones = Clones.deploy({"from": owner})
    # Deploy chicks SC
    chicks = GutterCatChicks.deploy(
        cats.address,
        rats.address,
        dogs.address,
        pigeons.address,
        clones.address,
        {"from": owner},
    )
    # Set up accounts with NFTs from Mock Collections
    cats.mint(accounts[1].address, 1, {"from": owner})
    rats.mint(accounts[2].address, 2, {"from": owner})
    dogs.mint(accounts[3].address, 3, {"from": owner})
    pigeons.mint(accounts[4].address, 4, {"from": owner})
    clones.mint(accounts[5].address, 5, {"from": owner})
    # Open presale
    chicks.setPresale(True, {"from": owner})
    # Mint
    price = chicks.presaleCost()
    chicks.presaleMint(0, 1, {"from": accounts[1], "amount": price})

    chicks.presaleMint(1, 2, {"from": accounts[2], "amount": price})

    chicks.presaleMint(2, 3, {"from": accounts[3], "amount": price})

    chicks.presaleMint(3, 4, {"from": accounts[4], "amount": price})

    chicks.presaleMint(4, 5, {"from": accounts[5], "amount": price})
