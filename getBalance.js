import { JsonRpcProvider, formatEther } from 'ethers';

async function getBalance() {
  // Connect to the Sepolia testnet using Alchemy's API
  const provider = new JsonRpcProvider("https://eth-sepolia.g.alchemy.com/v2/pN5R578E09YbnE8-nQ_ZGc0fY3FSsYqi");
  
  // Your Ethereum address
  const address = "0x133b74dc22B5D12da7dE14ee1f8670549240c68a";
  
  try {
    // Fetch the balance in wei
    const balance = await provider.getBalance(address);
    
    // Convert the balance from wei to Ether
    const balanceInEther = formatEther(balance);
    
    // Display the balance
    console.log(`The balance of ${address} is ${balanceInEther} ETH`);
  } catch (error) {
    // Handle any errors (e.g., network issues or invalid address)
    console.error("Error fetching balance:", error);
  }
}

// Execute the function
getBalance();