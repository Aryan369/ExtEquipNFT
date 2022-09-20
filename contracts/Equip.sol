// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "@rmrk-team/evm-contracts/contracts/RMRK/equippable/RMRKExternalEquip.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/access/OwnableLock.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// for dev
import "@rmrk-team/evm-contracts/contracts/RMRK/utils/RMRKEquipRenderUtils.sol";

//Minimal public implementation of RMRKEquippableWithNesting for testing.
contract Equip is OwnableLock, RMRKExternalEquip {
    using Strings for uint256;

    //Mapping of uint64 resource ID to tokenEnumeratedResource for tokenURI
    mapping(uint64 => bool) internal _tokenEnumeratedResource;

    //fallback URI
    string internal _fallbackURI;

    constructor(address nestingAddress, string memory fallbackURI_) RMRKExternalEquip (nestingAddress) {
        _fallbackURI = fallbackURI_;
    }

    // ---------------- RESOURCES ---------------- //

    function isTokenEnumeratedResource(uint64 resourceId)
        public
        view
        virtual
        returns (bool)
    {
        return _tokenEnumeratedResource[resourceId];
    }

    function setTokenEnumeratedResource(uint64 resourceId, bool state)
        external
        onlyOwner
    {
        _tokenEnumeratedResource[resourceId] = state;
    }

    function addResourceToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 overwrites
    ) external onlyOwner {
        // This reverts if token does not exist:
        ownerOf(tokenId);
        _addResourceToToken(tokenId, resourceId, overwrites);
    }

    function addResourceEntry(
        ExtendedResource calldata resource,
        uint64[] calldata fixedPartIds,
        uint64[] calldata slotPartIds
    ) external onlyOwner {
        _addResourceEntry(resource, fixedPartIds, slotPartIds);
    }

    function setValidParentRefId(
        uint64 refId,
        address parentAddress,
        uint64 partId
    ) external onlyOwner {
        _setValidParentRefId(refId, parentAddress, partId);
    }

    // ------------------------------------------- //

    // --------------- TOKEN URI ----------------- //

    function getFallbackURI() external view virtual returns (string memory) {
        return _fallbackURI;
    }

    function setFallbackURI(string memory fallbackURI) external onlyOwner {
        _fallbackURI = fallbackURI;
    }

    function _tokenURIAtIndex(uint256 tokenId, uint256 index)
        internal
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        if (_activeResources[tokenId].length > index) {
            uint64 activeResId = _activeResources[tokenId][index];
            Resource memory _activeRes = getResource(activeResId);
            string memory uri = string(
                abi.encodePacked(
                    _baseURI(),
                    _activeRes.metadataURI,
                    _tokenEnumeratedResource[activeResId]
                        ? tokenId.toString()
                        : ""
                )
            );

            return uri;
        } else {
            return _fallbackURI;
        }
    }

    // ----------------------------------------- //

    // ------------- NESTING ------------------- //

    function setNestingAddress(address _nestingAddress) public onlyOwner {
        _setNestingAddress(_nestingAddress);
    }

    // ----------------------------------------- //
}
