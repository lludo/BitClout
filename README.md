# BitClout
Some tools for the BitClout blockchain

1. The blockchain datamodel:
![Screenshot](/Docs/Screenshot.png)

2. Some Services, Managers and Tools I built:

- `NetworkClient`: Used to fetch all transactions given a `blockHeight` or an account `publicKey`
- `StorageClient`: Used to save, read or check that a block has been saved on disk
- `QueryManager`: Combine the `NetworkClient` &  `StorageClient` to provide a higher level API to fetch all blocks from `blockHeight` to the last available one. Persist the result on disk to not fetch the same block again if it's already been fetched.
- `StateManager`: Use the previous Classes to provide higher level API.
    - `refresh(completion:)`: To update the locally stored blocks with the newly available ones
    - `printAllTransactionForCreatorCoins(privateKey:)`: To print all the buy/sell that happened to a creator coin, given it's public key. This is printed in csv format where each line is `blockHeight,coinsValueChange`.

Here is an example of how this can be used:

```
let stateManager = StateManager()
stateManager.refresh() { error in
    guard error == nil else { return }
    
    let creatorKeyToFind = "BC1YLiWgKXYrpTkUZHyCbhfxU1bgJCQGcBvsQvPWuAwiVWnDFsvxudi" // @ludo
    stateManager.printAllTransactionForCreatorCoins(privateKey: creatorKeyToFind)
}
```

3. More to come... In the meantime, feel free to play with this, and contribute back you findings if you think this might help others :)