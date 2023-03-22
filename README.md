## Development Environment

See [OpenDSA-DevStack](https://github.com/OpenDSA/OpenDSA-DevStack) to set up a development environment from OpenDSA-LTI

## Export anonymized OpenDSA-LTI data

- OpenDSA stores massive interactions data and exercises attempts. If you want to use this data for learning analytics research tasks, you may need to export the data from the database and anonymize it first.

### Export and anonymize

- Export databse schema from https://opendsa-server.cs.vt.edu server using MySQL workbench data export tool
- Provision the OpenDSA-DevStack VM
- `vagrant ssh` into the VM
- `cd /vagrant/OpenDSA-LTI`
- `bundle exec rake db:drop`
- `bundle exec rake db:create`
- Connect to your local OpenDSA-DevStack using MySQL workbench and import the data using data import tool
- On OpenDSA-DevStack database do the follwoing:
- Relax the following constraints
    + alter table users drop index email;
    + alter table users drop index slug;
- Change the following configuration on workbench
    + Edit > Preferences > Sql Editor > uncheck the "Safe Updates"
- Execute the following update statements to anonymize the exported data
    + UPDATE `opendsa`.`users` SET `email` = "example@opendsa.org";
    + UPDATE `opendsa`.`users` SET `slug` = "example@opendsa.org";
    + UPDATE `opendsa`.`users` SET `first_name` = "first_name";
    + UPDATE `opendsa`.`users` SET `last_name` = "last_name";
    + UPDATE `opendsa`.`users` SET `encrypted_password` = "encrypted_password";
- Re-export the anynomized schema from OpenDSA-DevStack.

### Import anonymized data
- Provision the OpenDSA-DevStack VM
- `vagrant ssh` into the VM
- `cd /vagrant/OpenDSA-LTI`
- `bundle exec rake db:drop`
- `bundle exec rake db:create`
- Connect to your local OpenDSA-DevStack using Mysql workbench and import the anonymized data using data import tool
