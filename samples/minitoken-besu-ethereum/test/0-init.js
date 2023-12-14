const MiniToken = artifacts.require("MiniToken");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const bob = accounts[2];
  const mintAmount = 100;

  const miniToken = await MiniToken.deployed();
  const block = await web3.eth.getBlockNumber();
  await miniToken.mint(alice, mintAmount);
  const mintEvent = await miniToken.getPastEvents("Mint", { fromBlock: block });
  console.log(mintEvent);
  await miniToken.addAllowed(alice, bob, true);
  const addEvent = await miniToken.getPastEvents("AddAllowed", { fromBlock: block });
  console.log(addEvent);

  callback();
};
