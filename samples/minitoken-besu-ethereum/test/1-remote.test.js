const MiniToken = artifacts.require("MiniToken");

contract("MiniToken", (accounts) => {
  it("should Acknowledgement", async () => {
    const block = await web3.eth.getBlockNumber();
    MiniToken.deployed()
      .then((instance) =>
        instance.getPastEvents("Acknowledgement", {
          filter: { disclose: accounts[2]},
          fromBlock: block,
        })
      )
      .then((evt) => {
        assert.equal(
          evt[0].args.ack.valueOf(),
          1,
          "Acknowledgement should success"
        );
      });
  });
});
