/**
 * @title Crowd Fund Campaign Manager
 */
contract crowdfund {
    struct Contrib {
        address sender;
        uint value;
    }

    struct Campaign {
        address recipient;
        string title;
        uint goal;
        uint deadline;
        uint contrib_total;
        uint contrib_count;
        mapping(uint => Contrib) contribs;
    }

    mapping(uint => Campaign) campaigns;
    uint campaign_id = 0;

    /**
     * create a new crowfund campaign
     *
     * @param recipient the address to receive the payout when the goal is reached within the timelimit
     * @param title a arbitrary title for the campaign
     * @param goal the goal to reach
     * @param timelimit the deadline before which to reach the goal
     * @return the id the ID of the campaign created
     */
    function create_campaign(address recipient, string title, uint goal, uint timelimit) returns (uint) {
        uint id = campaign_id++;

        // check campaign doesn't already exist
        if (campaigns[id].recipient != 0x0) {
            return 0;
        }

        campaigns[id] = Campaign(recipient, title, goal, block.timestamp + timelimit, 0, 0);
        return id;
    }

    /**
     * contribute to a campaign with the value send
     *
     * @param id the ID of the campaign to contribute to
     * @return 0 = doesn't exist, 1 = funded, 2 = expired, 0 = contributed
     */
    function contribute(uint id) returns (uint) {
        // make sure campaign exists
        if (campaigns[id].recipient == 0x0) {
            return 0;
        }

        // Update contribution total
        uint total_contributed = campaigns[id].contrib_total + msg.value;
        campaigns[id].contrib_total = total_contributed;

        // Record new contribution
        uint sub_index = campaigns[id].contrib_count;
        campaigns[id].contribs[sub_index] = Contrib(msg.sender, msg.value);
        campaigns[id].contrib_count = sub_index + 1;

        // Enough funding?
        if (total_contributed >= campaigns[id].goal) {
            campaigns[id].recipient.send(total_contributed);
            clear(id);
            return 1;
        }

        // Expired?
        if (block.timestamp > campaigns[id].deadline) {
            uint i = 0;
            uint c = campaigns[id].contrib_count;
            while (i < c) {
                campaigns[id].contribs[i].sender.send(campaigns[id].contribs[i].value);
                i += 1;
            }
            clear(id);
            return 2;
        }

        return 0;
    }

    /**
     * get progress of a campaign
     *
     * @param id the ID of the campaign to get the progress for
     * @return the current total of contributions
     */
    function progress_report(uint id) returns (uint) {
        return campaigns[id].contrib_total;
    }

    /**
     * internal function to clear a funded/expired campaign
     *
     * @param id the ID of the campaign to clear
     * @dev private
     */
    function clear(uint id) private {
        delete campaigns[id];
    }
}