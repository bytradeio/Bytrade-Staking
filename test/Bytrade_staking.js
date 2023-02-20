const Bytrade_Staking = artifacts.require("Bytrade_Staking");

contract("Bytrade_Staking", async accounts => {
  it("should stake tokens", async () => {
    const stakingContract = await Bytrade_Staking.deployed();
    const tokenAddress = "0x1234567890123456789012345678901234567890"; // replace with a real token address
    const amount = 100 * 10**18; // 100 BTT
    const tenure = 12; // 12 months
    await stakingContract.stake(tenure, amount, { from: accounts[0] });
    const deposits = await stakingContract.getUserDeposits(accounts[0]);
    assert.equal(deposits.length, 1);
    assert.equal(deposits[0].amount, amount);
    assert.equal(deposits[0].endTime, Math.floor(Date.now() / 1000) + (tenure * 30 * 24 * 60 * 60)); // check that end time is 12 months from now
  });

  it("should unstake tokens with interest", async () => {
    const stakingContract = await Bytrade_Staking.deployed();
    const tokenAddress = "0x1234567890123456789012345678901234567890"; // replace with a real token address
    const amount = 100 * 10**18; // 100 BTT
    const tenure = 12; // 12 months
    await stakingContract.stake(tenure, amount, { from: accounts[0] });
    await new Promise(resolve => setTimeout(resolve, 1000)); // wait for 1 second
    const deposits1 = await stakingContract.getUserDeposits(accounts[0]);
    assert.equal(deposits1.length, 1);
    assert.equal(deposits1[0].amount, amount);
    await stakingContract.unstake(0, { from: accounts[0] });
    const deposits2 = await stakingContract.getUserDeposits(accounts[0]);
    assert.equal(deposits2.length, 0);
  });
});
