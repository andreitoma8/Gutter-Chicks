from brownie import GutterCatChicks, Cats, Dogs, Rats, Pigeons, Clones, accounts
import brownie


def test_main():
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
    with brownie.reverts():
        chicks.mint(1, {"from": owner, "amount": price})
        chicks.presaleMint(0, 1, {"from": accounts[1]})
        chicks.presaleMint(0, 1, {"from": owner, "amount": price})
    chicks.presaleMint(0, 1, {"from": accounts[1], "amount": price})
    assert chicks.balanceOf(accounts[1].address) == 1
    chicks.presaleMint(1, 2, {"from": accounts[2], "amount": price})
    assert chicks.balanceOf(accounts[2].address) == 1
    chicks.presaleMint(2, 3, {"from": accounts[3], "amount": price})
    assert chicks.balanceOf(accounts[3].address) == 1
    chicks.presaleMint(3, 4, {"from": accounts[4], "amount": price})
    assert chicks.balanceOf(accounts[4].address) == 1
    chicks.presaleMint(4, 5, {"from": accounts[5], "amount": price})
    assert chicks.balanceOf(accounts[5].address) == 1
    with brownie.reverts():
        chicks.presaleMint(1, 2, {"from": accounts[2], "amount": price})
        chicks.stake(1, {"from": accounts[1]})
