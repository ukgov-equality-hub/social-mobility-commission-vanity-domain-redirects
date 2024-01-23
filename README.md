# What is this?
This is the code behind the Social Mobility Commission "vanity" domain names:
* [socialmobilitycommission.org](https://socialmobilitycommission.org/)
* [socialmobilitycommission.com](https://socialmobilitycommission.com/)
* [socialmobilitycommission.co.uk](https://socialmobilitycommission.co.uk/)
* [socialmobilitycommission.org.uk](https://socialmobilitycommission.org.uk)

These domain names all redirect to the "official" domain name:
* [socialmobility.independent-commission.uk](https://socialmobility.independent-commission.uk/)

Most requests will redirect to the homepage of the "official" domain name.  
But there are some specific redirects configured.  
e.g.:
* `/ChildsPlay` redirects to https://socialmobility.independent-commission.uk/itschildsplay/

# How do I configure the redirects?
1. Ask a member of the team for editing permissions on this GitHub repository
2. Edit the file: [configure_the_redirects.json](./terraform/configure_the_redirects.json) (in the `terraform` folder)
3. Save the file.  
   This will run a [GitHub Action](https://github.com/ukgov-equality-hub/social-mobility-commission-vanity-domain-redirects/actions) and the changes will be uploaded to our cloud hosting