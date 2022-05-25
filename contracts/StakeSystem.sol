// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFT.sol";
import "./Coin.sol";

contract StakeSystem is Ownable {
    using SafeMath for uint256;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    NFT public nft; // NFT contract address
    Coin public coin; // coin contract address

    uint256 private constant lockTime30 = 30 days;
    uint256 private constant lockTime60 = 60 days;
    uint256 private constant lockTime120 = 120 days;
    uint256 public constant lockTimeRewards30Days = 77 ether; // 77 coin
    uint256 public constant lockTimeRewards60Days = 777 ether; // 777 coin
    uint256 public constant lockTimeRewards120Days = 7777 ether; // 7 777 coin

    mapping(uint256 => uint256) public tokenRewards; //mapping of the token rewards
    struct StakerInformation {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndex;
        uint256 balance;
        uint256 rewardsEarned;
        uint256 lastUpdate;
    }
    mapping(address => StakerInformation) public NFTStakers; // mappings of information of the Stacker
    struct NFTInformation {
        uint256 lockPeriod;
        uint256 rewards;
    }
    mapping(uint256 => NFTInformation) NFTInfos; // mapping of information of the NFT
    mapping(uint256 => address) public tokenOwner; // link token id to token owner address

    constructor(NFT _nft, Coin _coin) public {
        transferOwnership(msg.sender);
        nft = _nft;
        coin = _coin;
    }

    /**
     * @dev get all stacked token by the user
     * @param _user: stacker wallet address
     */
    function getUserStakedTokens(address _user)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        return NFTStakers[_user].tokenIds;
    }

    /**
     * @dev stake function
     * @param _tokenId: token ID of the Token
     * @param _lockPeriod: time to stake NFT
     */
    function stake(uint256 _tokenId, uint256 _lockPeriod) external {
        _stake(msg.sender, _tokenId, _lockPeriod);
    }

    /**
     * @dev main function of the stake
     * @param _user: user wallet address
     * @param _tokenId: token ID of the Token
     * @param _lockPeriod: time to stake NFT
     */
    function _stake(
        address _user,
        uint256 _tokenId,
        uint256 _lockPeriod
    ) internal {
        uint256 _lockPeriodUINT = _lockPeriod * 1 days;
        StakerInformation storage staker = NFTStakers[_user];
        require(
            nft.isApprovedForAll(_user, address(this)) == true,
            "NFT: PLEASE_APPROVE_THIS_CONTRACT"
        );
        require(
            _lockPeriodUINT >= lockTime30,
            "NFT: LOCK_PERIOD_MUST_BE_MORE_THAN_30"
        );
        if (staker.tokenIds.length > 0) {
            updateReward(_user);
        }
        staker.tokenIds.push(_tokenId);
        tokenOwner[_tokenId] = _user;
        staker.tokenIndex[staker.tokenIds.length - 1];
        staker.lastUpdate = block.timestamp;

        NFTInformation storage _nftInfos = NFTInfos[_tokenId];
        _nftInfos.lockPeriod = block.timestamp + _lockPeriodUINT;

        if (_lockPeriodUINT >= lockTime120) {
            _nftInfos.rewards = lockTimeRewards120Days;
        } else if (_lockPeriodUINT >= lockTime60) {
            _nftInfos.rewards = lockTimeRewards60Days;
        } else {
            _nftInfos.rewards = lockTimeRewards30Days;
        }
        nft.safeTransferFrom(_user, address(this), _tokenId);
    }

    /**
     * @dev unstake function just callable by the staker
     * @param _tokenId: token ID of the Token
     */
    function unstake(uint256 _tokenId) external {
        _unstake(msg.sender, _tokenId);
    }

    /**
     * @dev main function of the unstake
     * @param _user: stacker wallet address
     * @param _tokenId: token ID of the Token
     */
    function _unstake(address _user, uint256 _tokenId) internal {
        NFTInformation storage _nftInfos = NFTInfos[_tokenId];
        StakerInformation storage staker = NFTStakers[_user];
        require(
            block.timestamp > _nftInfos.lockPeriod,
            "NFT: YOUR_NFT_IS_STILL_LOCKED"
        );
        require(
            tokenOwner[_tokenId] == _user,
            "NFT: YOU_ARE_NOT_OWNER_OF_THIS_NFT"
        );
        updateReward(_user);
        uint256 lastIndex = staker.tokenIds.length - 1;
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        uint256 tokenIdIndex = staker.tokenIndex[_tokenId];

        staker.tokenIds[tokenIdIndex] = lastIndexKey;
        staker.tokenIndex[lastIndexKey] = tokenIdIndex;
        staker.lastUpdate = block.timestamp;
        if (staker.tokenIds.length > 0) {
            for (uint256 i; i < staker.tokenIds.length; i++) {
                if (staker.tokenIds[i] == _tokenId) {
                    staker.tokenIds[i] = staker.tokenIds[staker.tokenIds.length - 1]; // send the element to the end
                    staker.tokenIds.pop(); // delete the last element
                    break;
                }
            }
            delete staker.tokenIndex[_tokenId];
        }
        if (staker.balance == 0) {
            delete NFTStakers[_user];
        }
        delete tokenOwner[_tokenId];
        nft.safeTransferFrom(address(this), _user, _tokenId);
    }
    /**
     * @dev update rewards of the user
     * @param _user: stacker wallet address
     */
    function updateReward(address _user) internal {
        StakerInformation storage _staker = NFTStakers[_user];
        uint256 _rewards;
        for (uint256 i = 0; i <= _staker.tokenIds.length - 1; i++) {
            uint256 _tokenID = _staker.tokenIds[i];
            NFTInformation storage _nftInfos = NFTInfos[_tokenID];
            _rewards += _nftInfos.rewards;
        }
        uint256 blockTime = block.timestamp.sub(_staker.lastUpdate);
        uint256 pending = _rewards.mul(blockTime).div(86400);
        _staker.lastUpdate = block.timestamp;
        _staker.balance += pending;
    }

    /**
     * @dev get total claimable rewards by the user
     * @param _user: stacker wallet address
     */
    function getTotalClaimable(address _user) public view returns (uint256) {
        StakerInformation storage _staker = NFTStakers[_user];
        uint256 _rewards;
        for (uint256 i = 0; i <= _staker.tokenIds.length - 1; i++) {
            uint256 _tokenID = _staker.tokenIds[i];
            NFTInformation storage _nftInfos = NFTInfos[_tokenID];
            _rewards += _nftInfos.rewards;
        }
        uint256 blockTime = block.timestamp.sub(_staker.lastUpdate);
        uint256 pending = _rewards.mul(blockTime).div(86400);
        return _staker.balance + pending;
    }

    /**
     * @dev claim coin rewards by the staker
     */
    function claimReward() public {
        updateReward(msg.sender);
        StakerInformation storage _staker = NFTStakers[msg.sender];
        uint256 _rewards = _staker.balance;
        require(_rewards > 0, "NFT: REWARDS_BALACNE_TO_LOW");
        _staker.balance = 0;
        coin.payRewards(msg.sender, _rewards);
    }

    /**
     * @dev check if contract received an erc721
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    ) public returns (bytes4) {
        return _ERC721_RECEIVED;
    }

    /**
     * @dev withdraw by Contract owner
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
