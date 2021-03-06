require 'csv'
namespace :import do
  desc "Import Old Users"
  task :old_users => :environment do
    file = Rails.root.join("lib/tasks/old_users.csv")
    CSV.foreach(file, :headers => true) do |row|
      row = row.to_hash
      pwd = User.random_md5_pwd
      unless row["created"].nil?
        join_date = Date.strptime(row["created"],'%m/%d/%Y')
        u = User.new(
          email: row["email"],
          password: pwd,
          password_confirmation: pwd,
          auto_renew: false,
          membership_expiration: join_date + 1.year,
          first_name: row["first_name"],
          last_name: row["last_name"],
          phone_number: row["phone"],
          street_address: row["street"],
          city: row["city"],
          province: row["province"],
          country: row["country"],
          postal_code: row["postal_code"],
          plan_id: row["plan"]
        )
        if u.save then
          #add to mailchimp
          m = Mailchimp.new
          m.add_user(u)
          #change membership type on mailchimp
          m.change_membership(u,"member")
          #send new email?
          um = UserMailer.new
          um.created_account(u,pwd)          
        else
          puts u.errors.messages.inspect
        end
      else
        puts "Could not create row for: #{row['first_name']} #{row['last_name']}"
      end
    end
  end
end 