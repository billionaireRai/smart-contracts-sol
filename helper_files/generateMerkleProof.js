// will be used in VS code for merkle proof...

import { MerkleTree } from 'merkletreejs';
import keccak256 from 'keccak256';

// { address : tokens } object (whitelisted accounts)...
// const addressTokenObj = { '0x...v34g3' : 50 } ;

// Create leaves
export function createLeavesForAcc(addressTokenObj) {
  const leaves = Object.entries(addressTokenObj).map(([address, tokens]) =>
      keccak256(Buffer.from(address.slice(2) + tokens.toString(16).padStart(64, '0'), 'hex'))
  );

  return leaves ;
}

// Build tree
export function buildAndGetTreeRoot() {
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const root = tree.getHexRoot();

    return { tree , root } ;
}


// Generate proof for any address say 0x742d35Cc6634C0532925a3b8D17378114f8e73b6...
export function generateProofForAddress(address,tokens) {
    const leaf = keccak256(Buffer.from(address.slice(2) + tokens.toString(16).padStart(64, '0'), 'hex'));
    const proof = tree.getHexProof(leaf);

    return { proof , verification:tree.verify(proof, leaf, root) };

}