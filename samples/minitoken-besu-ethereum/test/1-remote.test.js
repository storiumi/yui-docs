const MiniToken = artifacts.require("MiniToken");

contract("MiniToken", (accounts) => {
  it("should RemoteCall", async () => {
    const block = await web3.eth.getBlockNumber();
    MiniToken.deployed()
      .then((instance) =>
        instance.getPastEvents("Acknowledement", {
          filter: { disclose: accounts[2]},
          fromBlock: block,
        })
      )
      .then((evt) => {
        assert.equal(
          evt[0].args.ack.valueOf(),
          0,
          "0 wasn't in Alice account"
        );
      });
  });
});
