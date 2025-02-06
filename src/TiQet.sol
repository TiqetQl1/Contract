// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Pool.sol";

contract TiQetV1 {
    Pool[] closed_pools;
    Pool[] active_pools;

    uint256 constant NOTFOUND = type(uint256).max;

    address public GOD;
    // Wont use mapping to able to list them
    address[] admins ;

    error NotAuthorized();

    modifier onlyGOD{
        if (msg.sender != GOD) {
            revert NotAuthorized();
        }
        _;
    }
    modifier onlyAdmin{
        if (!isAdmin(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    event PoolCreated(Pool indexed pool);
    event PoolArchived(Pool indexed pool);
    event PoolRemoved(Pool indexed pool);

    constructor(){
        GOD = msg.sender;
    }

    /**
      * Admins management functions
      */
    function transferGod(address ngod)  public onlyGOD{
        GOD = ngod;
    }
    function promote(address new_admin) public onlyGOD {
        require(!isAdmin(new_admin), "Already admin");
        admins.push(new_admin);
    }
    function demote(address old_admin)      public onlyGOD {
        uint256 index = adminIndex(old_admin);
        require(index != NOTFOUND, "Not an admin");
        admins[index] = admins[admins.length-1];
        admins.pop();
    }
    function isAdmin(address toCheck)   public view returns (bool){
        return ((toCheck == GOD) || (adminIndex(toCheck)!=NOTFOUND));
    }


    /**
      * returns a small number ( zero included) if the address is in the admins
      */
    function adminIndex(address needle) internal view returns (uint256){
        for (uint256 i=0; i<admins.length; i++) 
        {
            if (admins[i] == needle){
                return i;
            }
        }
        return NOTFOUND;
    }

    /**
      * Functions to manage pools
      */
    function popAt(uint256 index) private onlyAdmin {
        active_pools[index] = active_pools[active_pools.length - 1];
        active_pools.pop();
    }
    function dropPool(uint256 index, bool should_archive) public onlyAdmin {
        if (should_archive) {
            closed_pools.push(active_pools[index]);
            emit PoolArchived(active_pools[index]);
        }else{
            emit PoolRemoved(active_pools[index]);
        }
        popAt(index);
    }
    function importPool(Pool pool) public onlyAdmin{
        active_pools.push(pool);
    }
    function allActives() external view returns(Pool[] memory) {
        return active_pools;
    }
    function allArchived() external view returns(Pool[] memory) {
        return closed_pools;
    }
    function newPool(
        address    organizer,
        uint256    time_end, 
        uint256    time_start,
        uint256    ticket_price_usdt,
        uint256    max_tickets_total,  
        uint256    max_participants,
        uint256    max_tickets_of_participant,
        uint256    winners_count,
        uint256    cut_share,
        uint256    cut_per_nft,
        uint256    cut_per_winner
        ) external returns (Pool pool){
        pool = new Pool(
            (organizer!=address(0)) 
                    ? organizer 
                    : msg.sender,
            time_end, 
            time_start,
            ticket_price_usdt,
            max_tickets_total,  
            max_participants,
            max_tickets_of_participant,
            winners_count,
            cut_share,
            cut_per_nft,
            cut_per_winner
            );
        if (isAdmin(msg.sender)) {
            active_pools.push(pool);
            emit PoolCreated(pool);
        }
    }

    /**
      * Just in case
      */
      function withdraw() external onlyGOD returns(bool status) {
        (status, ) = GOD.call{value: address(this).balance}("");
      }
}