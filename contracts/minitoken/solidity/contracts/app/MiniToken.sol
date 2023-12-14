// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@hyperledger-labs/yui-ibc-solidity/contracts/apps/commons/IBCAppBase.sol";
import "@hyperledger-labs/yui-ibc-solidity/contracts/core/25-handler/IBCHandler.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../lib/Packet.sol";

contract MiniToken is IBCAppBase {
    IBCHandler ibcHandler;

    using BytesLib for *;

    address private owner;

    constructor(IBCHandler ibcHandler_) {
        owner = msg.sender;

        ibcHandler = ibcHandler_;
    }

    event Mint(address indexed to, uint256 amount);

    event Burn(address indexed from, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event AddAllowed(address indexed allowed, address indexed disclose);

    event RemoteCall(address indexed requester, address indexed disclose);

    event Acknowledgement(address indexed disclose, uint256 ack);

    modifier onlyOwner() {
        require(msg.sender == owner, "MiniToken: caller is not the owner");
        _;
    }

    function ibcAddress() public view override returns (address) {
        return address(ibcHandler);
    }

    function remoteContractCall(
        address requester,
        address remoteaddress,
        string calldata sourcePort,
        string calldata sourceChannel,
        uint64 timeoutHeight
    ) external {
        require(_allowed[requester][remoteaddress], "MiniToken: not allowed");
        _sendPacket(
            MiniTokenPacketData.Data({
                requester: abi.encodePacked(requester),
                disclose: abi.encodePacked(remoteaddress)
            }),
            sourcePort,
            sourceChannel,
            timeoutHeight
        );
        emit RemoteCall(requester, remoteaddress);
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => bool)) private _allowed;

    function addAllowed(address requester, address disclose, bool isAllowed) external {
        require(_addAllowed(requester, disclose, isAllowed));
    }

    function checkAllowed(address requester, address disclose) external view returns (bool) {
        return _allowed[requester][disclose];
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(_mint(account, amount));
    }

    function burn(uint256 amount) external {
        require(_burn(msg.sender, amount), "MiniToken: failed to burn");
    }

    function transfer(address to, uint256 amount) external {
        bool res;
        string memory message;
        (res, message) = _transfer(msg.sender, to, amount);
        require(res, message);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _addAllowed(address requester, address disclose, bool isAllowed)
        internal returns (bool)
    {
        _allowed[requester][disclose] = isAllowed;
        emit AddAllowed(requester, disclose);
        return true;
    }

    function _mint(address account, uint256 amount) internal returns (bool) {
        _balances[account] += amount;
        emit Mint(account, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal returns (bool) {
        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) {
            return false;
        }
        _balances[account] = accountBalance - amount;
        emit Burn(account, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool, string memory) {
        if (_balances[from] >= amount) {
            return (false, "MiniToken: amount shortage");
        }
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return (true, "");
    }

    /// Module callbacks ///

    function onRecvPacket(Packet.Data calldata packet, address /*relayer*/)
        external
        virtual
        override
        onlyIBC
        returns (bytes memory acknowledgement)
    {
        MiniTokenPacketData.Data memory data = MiniTokenPacketData.decode(
            packet.data
        );
        return
            _newAcknowledgement(abi.encodePacked(balanceOf(data.disclose.toAddress(0))));
    }

    function onAcknowledgementPacket(
        Packet.Data calldata packet,
        bytes calldata acknowledgement,
        address /*relayer*/
    ) external virtual override onlyIBC {
        uint256 decoded = abi.decode(acknowledgement, (uint256));
        emit Acknowledgement(MiniTokenPacketData.decode(packet.data).disclose.toAddress(0), decoded);
    }

    function onChanOpenInit(
        Channel.Order,
        string[] calldata connectionHops,
        string calldata portId,
        string calldata channelId,
        ChannelCounterparty.Data calldata counterparty,
        string calldata version
    ) external virtual override {}

    function onChanOpenTry(
        Channel.Order,
        string[] calldata connectionHops,
        string calldata portId,
        string calldata channelId,
        ChannelCounterparty.Data calldata counterparty,
        string calldata version,
        string calldata counterpartyVersion
    ) external virtual override {}

    function onChanOpenAck(
        string calldata portId,
        string calldata channelId,
        string calldata counterpartyVersion
    ) external virtual override {}

    function onChanOpenConfirm(
        string calldata portId,
        string calldata channelId
    ) external virtual override {}

    function onChanCloseConfirm(
        string calldata portId,
        string calldata channelId
    ) external virtual override {}

    function onChanCloseInit(
        string calldata portId,
        string calldata channelId
    ) external virtual override {}

    // Internal Functions //

    function _sendPacket(
        MiniTokenPacketData.Data memory data,
        string memory sourcePort,
        string memory sourceChannel,
        uint64 timeoutHeight
    ) internal virtual {
        ibcHandler.sendPacket(
            sourcePort,
            sourceChannel,
            Height.Data({
                revision_number: 0,
                revision_height: timeoutHeight
            }),
            0,
            MiniTokenPacketData.encode(data)
        );
    }

    function _newAcknowledgement(bytes memory ack)
        internal
        pure
        virtual
        returns (bytes memory)
    {
        return ack;
    }
}
