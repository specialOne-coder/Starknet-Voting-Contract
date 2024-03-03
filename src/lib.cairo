use starknet::ContractAddress;
#[starknet::interface]
trait IVotingContract<TContractState> {
    fn vote(ref self: TContractState, vote: felt252);
    fn get_votes(self: @TContractState) -> (felt252, felt252);
}

#[starknet::contract]
mod VotingContract {
    use starknet::get_caller_address;
    use traits::Into;
    use super::{IVotingContract, ContractAddress};

    #[storage]
    struct Storage {
        proposal: felt252,
        owner: ContractAddress,
        yes_votes: felt252,
        no_votes: felt252,
        voters: LegacyMap::<ContractAddress, bool>,
    }

     /// @dev Event that gets emitted when a vote is cast
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        VoteCast: VoteCast
    }

    /// @dev Represents a vote that was cast
    #[derive(Drop, starknet::Event)]
    struct VoteCast {
        voter: ContractAddress,
        vote: felt252,
    }

    /// @dev Contract constructor initializing the contract with a proposal
    #[constructor]
    fn constructor(
        ref self: ContractState,
        init_proposal: felt252
    ) {
        let caller = get_caller_address();
        self.owner.write(caller);
        self.proposal.write(init_proposal);
    }

    /// @dev allow voting
    #[external(v0)]
    impl VotingContractImpl of IVotingContract<ContractState> {
        fn vote(ref self: ContractState, vote: felt252) {
            assert((vote == 0) || (vote == 1), 'vote can only be 0/1');
            let caller = get_caller_address();

            assert(!self.voters.read(caller), 'you have already voted');

            if vote == 0 {
                self.no_votes.write(self.no_votes.read() + 1);
            } else if vote == 1 {
                self.yes_votes.write(self.yes_votes.read() + 1);
            }

            self.voters.write(caller, true);
            self.emit(VoteCast { voter: caller, vote: vote });
        }

        /// @dev get results 
        fn get_votes(self: @ContractState) -> (felt252, felt252) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'NOT_OWNER');
            (self.no_votes.read(), self.yes_votes.read())
        }
    }
}