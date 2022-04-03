// SPDX-License-Identifier: MIT
/**
 * @file fractionalClaim.sol
 * @author Jackson Ng <jackson@jacksonng.org>
 * @date created 20th Mar 2022
 * @date last modified 20th Mar 2022
 */

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FractionalClaim {

    using SafeMath for uint256;

    address payable public ownerAddress;
    address public nftAddress;
    address public tokenAddress;
    enum ClaimState {initiated, accepting, closed}
    ClaimState public claimState;
    uint256 public funds;
    uint256 public supply;

    event funded();

    //this claims contract should only be allowed if the guy who started it owns this NFT token
    modifier isOwnerOfNFT(address _nftAddress, address _ownerAddress, uint256 _tokenID){
        require(ERC721(_nftAddress).ownerOf(_tokenID) == _ownerAddress);
        _;
    }

	modifier condition(bool _condition) {
		require(_condition);
		_;
	}
	modifier onlyOwner() {
		require(msg.sender == ownerAddress);
		_;
	}

    modifier inClaimState(ClaimState _state) {
		require(claimState == _state);
		_;
	}

    modifier correctToken(address _token){
        require(_token == tokenAddress);
        _;
    }

    constructor(address _nftAddress, uint256 _tokenID)
        isOwnerOfNFT(_nftAddress, msg.sender, _tokenID)
    {
        nftAddress = _nftAddress;
        ownerAddress = payable(msg.sender);
        claimState = ClaimState.initiated;
    }

    function fund(address _token)
        public
        payable
        inClaimState(ClaimState.initiated)
        onlyOwner
    {
        funds = msg.value;                                                //amount added to allow claims to be made
        tokenAddress = _token;                                            //address of acceptable token
        claimState = ClaimState.accepting;                                //set to accepting status

        supply = ERC20(_token).totalSupply().div(1000000000000000000);    //find out how many tokens are out there
  
        emit funded();
    }

    function claim(address _token, uint256 _amount) 
        public 
        payable
        correctToken(_token)
    {
        ERC20Burnable(_token).transferFrom(msg.sender, address(this), _amount*1000000000000000000); //collect the token back, not working yet
        ERC20Burnable(_token).burn( _amount*1000000000000000000);                                   //claimed, so burn this token
        payable(msg.sender).transfer((_amount*1000000000000000000).div(supply));                    //send the ETH to the claimant

        //ok, fully claimed. Close this contract
        if (ERC20Burnable(_token).totalSupply() == 0){
            claimState = ClaimState.closed;
        }
    }
}