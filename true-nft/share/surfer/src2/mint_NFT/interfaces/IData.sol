pragma ton-solidity >= 0.43.0;

interface IData {
    function getOwner() external view returns (address addrOwner, address addrNftData, string comment, string comment1, string comment2, string comment3);
    function getInfo() external view returns (
        mapping(uint128 => bytes) content,
        address author,
        string name,
        string description,
        string tokenCode,
        uint64 creationDate,
        string comment,
        string comment1,
        string comment2,
        string comment3
    );
}
