/**
 * 
 * SNSEngine
 * afterInstallEngine
 * - only callable by collection
 * - should deploy a new SNS contract, set SNS address, set price to max int
 * 
 * mint
 * - requires value to equal price
 * - set new balance correctly
 * - mint new name for sender
 * 
 * setName
 * - can only set a name to its holder
 * - sets new name
 * 
 * mintAndSet
 * - mints and sets name
 * - fails with wrong value
 * 
 * setPrice
 * - only callable by collection or collection owner
 * - sets price
 * 
 * getBalance
 * - reads balance correctly
 * 
 * withdraw
 * - withdraws balance to collection owner
 * 
 * getTokenURI
 * - returns name of a token
 * 
 * 
 * 
 */