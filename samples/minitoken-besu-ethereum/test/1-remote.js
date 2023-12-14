const MiniToken = artifacts.require("MiniToken");

module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const alice = accounts[1];
  const bob = accounts[2];

  const port = "transfer";
  const channel = "channel-0";
  const timeoutHeight = 10000000;

  const miniToken = await MiniToken.deployed();
  const result = await miniToken.remoteContractCall(alice, bob, port, channel, timeoutHeight);

  console.log(result)
  const remoteCall = await miniToken.getPastEvents("RemoteCall", {
    fromBlock: 0,
  });
  console.log(remoteCall);

  callback();
};
