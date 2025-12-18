// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDTTRC20 {
    string public name = "USDT TRC20";
    string public symbol = "USDT";
    uint8 public decimals = 6;
    uint256 public _totalSupply;

    address public owner;
    address public upgradedAddress;
    bool public deprecated;

    uint256 public basisPointsRate = 0;
    uint256 public maximumFee = 0;

    mapping(address => bool) public isBlackListed;
    mapping(address => uint256) public oldBalanceOf;

    bool public paused;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public constant MAX_UINT = type(uint256).max;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);
    event DestroyedBlackFunds(address indexed _blackListedUser, uint256 _balance);
    event Issue(uint256 amount);
    event Redeem(uint256 amount);
    event Deprecate(address newAddress);
    event Params(uint256 feeBasisPoints, uint256 maxFee);
    event Pause();
    event Unpause();

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notBlackListed {
        require(!isBlackListed[msg.sender]);
        _;
    }

    modifier notPaused {
        require(!paused);
        _;
    }

    constructor() {
        _totalSupply = 5000000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = _totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public notBlackListed notPaused returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);

        uint256 fee = calcFee(_value);
        require(balanceOf[msg.sender] >= _value);
        uint256 sendAmount = _value - fee;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += sendAmount;
        if (fee > 0) {
            balanceOf[owner] += fee;
        }
        emit Transfer(msg.sender, _to, sendAmount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notPaused returns (bool success) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);

        uint256 fee = calcFee(_value);
        uint256 sendAmount = _value - fee;

        balanceOf[_from] -= _value;
        balanceOf[_to] += sendAmount;
        if (fee > 0) {
            balanceOf[owner] += fee;
        }
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, sendAmount);
        return true;
    }

    function approve(address _spender, uint256 _value) public notBlackListed notPaused returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public notBlackListed notPaused returns (bool success) {
        allowance[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public notBlackListed notPaused returns (bool success) {
        uint256 oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function setParams(uint256 newBasisPoints, uint256 newMaxFee) public onlyOwner {
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee;
        emit Params(basisPointsRate, maximumFee);
    }

    function calcFee(uint256 _value) public view returns (uint256) {
        uint256 fee = (_value * basisPointsRate) / 10000;
        return fee > maximumFee ? maximumFee : fee;
    }

    function issue(uint256 amount) public onlyOwner {
        require(amount > 0);
        _totalSupply += amount;
        balanceOf[owner] += amount;
        emit Issue(amount);
        emit Transfer(address(0), owner, amount);
    }

    function redeem(uint256 amount) public onlyOwner {
        require(amount > 0);
        require(balanceOf[owner] >= amount);
        _totalSupply -= amount;
        balanceOf[owner] -= amount;
        emit Redeem(amount);
        emit Transfer(owner, address(0), amount);
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        oldBalanceOf[_evilUser] = balanceOf[_evilUser];
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function getBlackListStatus(address _maker) public view returns (bool) {
        return isBlackListed[_maker];
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint256 balance = balanceOf[_blackListedUser];
        balanceOf[_blackListedUser] = 0;
        _totalSupply -= balance;
        emit DestroyedBlackFunds(_blackListedUser, balance);
    }

    function pause() public onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpause();
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



