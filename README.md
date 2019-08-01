## Stack
| Function              |                                |                         |                               |
| --------------------- | ------------------------------ | ----------------------- | ------------------------------|
| App                   | Ruby 2.5.3p105                 | Rails 5.1.6.1           | Slim 3.0.8                    |
| Database              | PG 0.21.0                      | Carrierwave 1.2.1       |                               |
| Webserver             | Puma 3.10.0                    | Foreman 0.84.0          | Figaro 1.1.1                  |
| Frontend              | Bootstrap 4.1.3                | Will_paginate 3.1.6     | Will_paginate-bootstrap4 0.1.3|
| User                  | Devise 4.5.0                   | Omniauth-facebook 4.0.0 | Omniauth-google-oauth2 0.5.2  |
| Payments              | Payola-payments 1.5.1          | Stripe 4.7.0            | Stripe Event 2.2.0            |
| Background processing | Active Elastic Job 2.0.1       | Redis 3.3.5             |                               |
| Youtube download      | youtube-dl.rb 0.3.1.2019.01.17 | yt 0.32.1               | yt-url 1.0.0                  |

## Localhost setup
In terminal run:
1.  `git clone git@github.com:naterexw/get_audio_from_video_rails.git`
2.  `cd get_audio_from_video_rails`
3.  Install in your system:
* (MacOS)
  1.  `brew install youtube-dl`
  2.  `brew install ffmpeg`
  3.  `brew install redis``
* (Ubuntu)
  1.  `sudo apt-get install youtube-dl`
  2.  `sudo apt-get install ffmpeg`
  3.  `sudo apt-get install redis-server`
4.  `bundle update`
5.  `RUBY_VERSION=2.5.3 bundle` (must bundle with this command since we use an environment variable to control Ruby version)
6.  Run `EDITOR="vim --wait" bin/rails credentials:edit` and add [this gist](https://gist.github.com/naterexw/fa050208bca76f42ac2240dc977142fa).  This will create `config/credentials.yml.enc`
7.  Create `.env` file in root and add line `PORT=3000`
8.  `rails db:create && rails db:migrate && rails db:seed`
9.  `echo "api_key: gZoonj01bnrWycbz4D7U40ClUkG7GzQB" > ~/.ultrahook`

## Running app in localhost
In separate terminal tabs run:
1.  `ultrahook stripe http://localhost:3000/payola/events`
2.  `redis-server`
3.  `rails server`

Then open [http://localhost:3000](http://localhost:3000/).

## Development emails
In `environments/development.rb`add:
```
# Devise mailer
config.action_mailer.default_url_options = { host: Rails.application.credentials[Rails.env.to_sym][:HTTP_HOST] || "localhost", port: 3000 }

# Mailcatcher
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = { :address => '127.0.0.1', :port => 1025 }
```
In terminal run:
1.  `gem install mailcatcher`
2.  `mailcatcher`
3.  Open [http://127.0.0.1:1080](http://127.0.0.1:1080/)

* To preview Devise emails, open [http://localhost:3000/rails/mailers/devise/mailer](http://localhost:3000/rails/mailers/devise/mailer)
* To preview Paypola emails, open [http://localhost:3000/rails/mailers/membership_mailer](http://localhost:3000/rails/mailers/membership_mailer)

## Amazon AWS
The app is hosted on Amazon AWS and requires both AWS CLI an EB CLI installed on local:
* [AWS CLI installation instructions](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html) (scroll to bottom for specific OS instructions)
* [EB CLI installation instructions](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html) (scroll to bottom for specific OS instructions)

### AWS Cloudformation
Cloudformation is used to manage the app infrastructure on AWS, everything from creating/updating/destroying the instances, to application environment variables.

All changes to infrastructure created by Cloudformation must be done through Cloudformation, since any later Cloudformation deploy would overwrite any manual changes!

All changes are done in [ElasticBeanstalk\_GAFV.template.yml](cloudformation/ElasticBeanstalk_GAFV.template.yml), with parameters configured in the [YAML files for each environment](https://gist.github.com/naterexw/4d085bc74bb22e44a76bdde6c2ec7f0b)

Cloudformation reference:
- [Cloudformation Resources reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)
- [Cloudformation Functions reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)
- [Elasticbeanstalk options](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html)

### Step 1: Create AWS stack
Cloudformation deploy is done using the file `bin/cloudformation-deploy` script.  You can view progress within [AWS Cloudformation console](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks)

Usage:
```sh
bin/cloudformation-deploy -c COMMAND -s STACK_NAME -e ENVIRONMENT_NAME

Usage: bin/cloudformation-deploy [options]
  -c, --command NAME               Command to execute (create,update,delete)
  -s, --stack-name NAME            Name of the stack to deploy
  -e, --environment-name NAME      Name of the environment to deploy (staging,production)
  -f, --force                      Force command without asking for params
  -h, --help                       Show this help
```
**[Cloudformation params YAML files can be found here using this link](https://gist.github.com/naterexw/4d085bc74bb22e44a76bdde6c2ec7f0b)**

To create an environment:
1. Create YAML params file in `cloudformation/elasticbeanstalk_params_{ENV}.yml` (see above for params gists)
2. Configure all the params in the file (Example: cloudformation/elasticbeanstalk_params_production.yml)
3. Run the cloudformation-deploy create code:
    ```sh
    bin/cloudformation-deploy -c create -s "gafv-production" -e "production"
    ```

To update an environment:
1. Update params in `cloudformation/elasticbeanstalk_params_{ENV}.yml` if needed
2. Run the cloudformation-deploy update command:
    ```sh
    bin/cloudformation-deploy -c update -s "gafv-production" -e "production"
    ```

To delete an environment:
**IMPORTANT NOTE: Deleting an environment will delete all resources configured (database, redis, etc) for the environment and make it unrecoverable. Make sure you want to do it!**
1. Empty the S3 buckets of the environment first before running delete, **otherwise delete will fail!**
2. Run the cloudformation-deploy delete command:
    ```sh
    bin/cloudformation-deploy -c delete -s "gafv-production" -e "production"
    ```

### Step 2: Deploy app code/update env variables
Deploying the app is done using `bin/deploy`
```sh
bin/deploy -e ENVIRONMENT_NAME

Usage: bin/deploy [options]
    -e, --environment-name NAME      Name of the environment to deploy (production, staging)
    -h, --help                       Show this help
```

Deploying affects all ElasticBeanstalk environments configured for the app. Environments are configured in `.elasticbeanstalk/config.yml.{ENV}` (They are symlinked to the current environment during deploy).

1. Deploy code to AWS CodeCommit
    ```sh
    git push code-commit master
    ```
2. Deploy code to environment (production)
    ```sh
    bin/deploy -e production
    ```
### (Optional) Step 3: Add new env variables
1. Add new env variable "Namespaces" for all environments in `cloudformation/ElasticBeanstalk_GAFV.template.yml`
2. Update params in `cloudformation/elasticbeanstalk_params_production.yml`
3. Deploy code to CodeCommit
4. Run update command again
    ```sh
    bin/cloudformation-deploy -c update -s "gafv-production" -e "production"
    ```
5. Run deploy command
    ```sh
    bin/deploy -e production
    ```

### (Optional) Step 4: Upgrade environment platform or Ruby version/add new env variables
1. In `cloudformation/ElasticBeanstalk_GAFV.template.yml`:
    * line 138 - uncomment & update for new EBPlatform (Example: change to Ruby26)
    * line 318 - uncomment & update for new WebEnv (Example: change to WebEnv26)
    * line 1098 - uncomment & update for new WorkerEnv (Example: change to WorkerEnv26 )
    * line 2405 - update MainWebDNSRecord->Properties->AliasTarget->DNSName->Fn::GetAtt: WebEnv (Example: change to WebEnv26)
    * line 2419 - update Outputs->URL->Value->Fn::Join->Fn::GetAtt: WebEnv (Example: change to WebEnv26)
3. Run update command
    ```sh
    bin/cloudformation-deploy -c update -s "gafv-production" -e "production"
    ```
4. In AWS ElasticBeanstalk console, swap environment URLs
5. In `cloudformation/ElasticBeanstalk_GAFV.template.yml`:
    * comment out old EBPlatform (Example: Ruby 25)
    * WebEnv & WorkerEnv objects (Example: WebEnv25, WorkerEnv25)
    * **DO NOT comment out MainWebDNSRecord or Output values**
6. Run update command again
    ```sh
    bin/cloudformation-deploy -c update -s "gafv-production" -e "production"
    ```
7. If getting error `Tried to delete resource record set [name='getaudiofromvideo.com.', type='A'] but the values provided do not match the current values`:
    * line 2392 - comment out MainWebDNSRecord object
    * Run update command again
    * In AWS Route 53, update apex A record to new LoadBalancer URL
    * uncomment MainWebDNSRecord object, then run update command again

### Running seed file on AWS postgres
To run the seed file on AWS postgres, uncomment the code in this file:
```
.ebextensions/seed.config
```

### AWS Elasticbeanstalk
Route 53 DNS:
1. ns-1372.awsdns-43.org
2. ns-124.awsdns-15.com
3. ns-1975.awsdns-54.co.uk
4. ns-665.awsdns-19.net

| Production        | Name                      | Size           | Number of instances |
| ----------------- | ------------------------- | -------------- | ------------------- |
| Webserver         | gafv-production-web       | t2.small       | 1                   |
| Conversion worker | gafv-production-worker    | t2.small       | 2                   |
| Postgres          | gafv_production_postgres  | db.t2.small    | 1                   |
| Redis             | gafv-production-reds      | cache.t2.micro | 1                   |
| Bastion           | gafv-production-bastion   | t2.nano        | 1                   |

| Staging           | Name                   | Size           | Number of instances |
| ----------------- | ---------------------- | -------------- | ------------------- |
| Webserver         | gafv-staging-web       | t2.nano        | 1                   |
| Conversion worker | gafv-staging-worker    | t2.nano        | 1                   |
| Postgres          | gafv_staging_postgres  | db.t2.micro    | 1                   |
| Redis             | gafv-staging-reds      | cache.t2.micro | 1                   |
| Bastion           | gafv-staging-bastion   | t2.nano        | 1                   |

### Security groups on AWS
All come from [this source](https://blog.cmgresearch.com/2017/05/01/deploying-a-rails-app-to-elastic-beanstalk.html)

| Group                            | Route    | Type            | Protocol | Port Range | Source        | Destination |
| -------------------------------- | -------- | --------------- | -------- | ---------- | ------------- | ----------- |
| Webserver                        | Inbound  | SSH             | TCP      | 22         | Bastion       |             |
| (gafv-production-web)            | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |
|                                  |          |                 |          |            |               |             |
|  Webserver  VPC                  | Inbound  | HTTP            | TCP      | 80         | Load Balancer |             |
| (gafv-production-web25)          | Inbound  | Custom TCP Rule | TCP      | 90         | Load Balancer |             |
|                                  | Inbound  | SSH             | TCP      | 22         | Bastion       |             |
|                                  | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |
|                                  |          |                 |          |            |               |             |
| Redis                            | Inbound  | Custom TCP Rule | TCP      | 6379       | Webserver     |             |
| (gafv-production-redis)          | Inbound  | Custom TCP Rule | TCP      | 6379       | Worker        |             |
|                                  | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |
|                                  |          |                 |          |            |               |             |
| Postgres                         | Inbound  | PostgreSQL      | TCP      | 5432       | Webserver     |             |
| (gafv-production-db)             | Inbound  | PostgreSQL      | TCP      | 5432       | Bastio        |             |
|                                  | Inbound  | PostgreSQL      | TCP      | 5432       | Worker        |             |
|                                  | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |
|                                  |          |                 |          |            |               |             |
| Load Balancer                    | Inbound  | HTTP            | TCP      | 80         | 0.0.0.0/0     |             |
| (gafv-production-elb)            | Inbound  | HTTPS           | TCP      | 443        | 0.0.0.0/0     |             |
|                                  | Outbound | HTTP            | TCP      | 80         |               | Webserver   |
|                                  | Outbound | Custom TCP Rule | TCP      | 90         |               | Webserver   |
|                                  |          |                 |          |            |               |             |
| Worker                           | Inbound  | SSH             | TCP      | 22         | Bastion       |             |
| (gafv-production-worker)         | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |
|                                  |          |                 |          |            |               |             |
| Worker VPC                       | Inbound  | SSH             | TCP      | 22         | Bastion       |             |
| (gafv-production-worker25)       | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |
|                                  |          |                 |          |            |               |             |
| Bastion                          | Inbound  | SSH             | TCP      | 22         | Nate          |             |
| (gafv-production-bastion)        | Inbound  | SSH             | TCP      | 22         | Nenad         |             |
|                                  | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |
|                                  |          |                 |          |            |               |             |
| Tinyproxy (not used)             | Inbound  | All traffic     | All      | All        | Bastion       |             |
| (gafv-tinyproxy)                 | Outbound | All traffic     | All      | All        |               | 0.0.0.0/0   |

### Autoscaling on AWS
| SQS queue          | <=> | CloudWatch metric  |
| ------------------ | --- | ------------------ |
| Messages in flight | =   | MessagesNotVisible |
| Messages Available | =   | MessagesVisible    |

gafv-eb-active-elastic-job (worker) uses the [following autoscaling rules](https://console.aws.amazon.com/ec2/autoscaling/home?region=us-east-1#AutoScalingGroups:id=awseb-e-adgnrq66c8-stack-AWSEBAutoScalingGroup-1HXOKNY7P4B0V;view=policies):

1.  ApproximateNumberOfMessagesVisible-Down
    * alarm threshold: ApproximateNumberOfMessagesNotVisible < 2 for 5 consecutive periods of 60 seconds
    * remove 1 instance
2.  ApproximateNumberOfMessagesVisible-Up
    * alarm threshold: ApproximateNumberOfMessagesVisible >= 5 for 5 consecutive periods of 60 seconds
    * add 1 instance

### Load balancer setup on AWS
In order to use Websockets on AWS, ELB needs to be configured to use plain TCP/SSL. This causes it to lose information about client IP, so [ProxyProtocol](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-proxy-protocol.html) needs to be used.

Actual commands ran to configure load balancer:
```sh
LB_NAME=awseb-e-g-AWSEBLoa-QJTXEA02960U
aws elb create-load-balancer-policy --load-balancer-name $LB_NAME --policy-name GAFVProxyProtocolPolicy --policy-type-name ProxyProtocolPolicyType --policy-attributes AttributeName=ProxyProtocol,AttributeValue=true
aws elb set-load-balancer-policies-for-backend-server --load-balancer-name $LB_NAME --instance-port 80 --policy-names GAFVProxyProtocolPolicy
```

### Cronjobs on AWS
* Cronjobs are set using Elasticbeanstalk [periodic task](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html#worker-periodictasks) feature.
* Check [active-elastic-job](https://github.com/tawan/active-elastic-job#set-up-periodic-tasks-cron-jobs) for details and [cron.yaml](/cron.yaml) for example.

## Youtube-dl

### (As of January 25, 2019, we are using youtube-dl release 2019.01.17)
Downloading videos are done via the Python youtube-dl command-line program, which has [periodic updates](https://github.com/rg3/youtube-dl/releases).

This Rails app uses a ruby wrapper of the python youtube-dl.  However, in order to get the latest python youtube-dl release, it is necesary to find the fork which has the most current binary version.  The list of the ruby wrapper forks [can be found here](https://github.com/layer8x/youtube-dl.rb/network).

### Exception/error tracking
Rollbar is used to track exceptions, which are [grouped by request.url](<https://rollbar.com/Primesite/GetAudioFromVideo.com/rql/?q=SELECT%20request.url%2C%20count(*)%0AFROM%20item_occurrence%0AWHERE%20item.counter%20%3D%2083%20AND%20timestamp%20%3E%20unix_timestamp()%20-%2060%20*%2060%20*%2024%0AGROUP%20BY%20request.url%0AORDER%20BY%20count(*)%20DESC%0Alimit%201000>).

### How to fix conversions not working
1. Check Rollbar exception traceback for details on conversion failure error. Common errors include:
    * *ERROR: The uploader has not made this video available in your country.*
    * *ERROR: Watch this video on YouTube. Playback on other websites has been disabled by the video owner.*
    * *ERROR: This video contains content from WMG, who has blocked it in your country on copyright grounds.*
2. Check Python youtube-dl [github issues](https://github.com/rg3/youtube-dl/issues) for common community errors & fixes.
3. Find & update gemfile to the [newest version of youtube-dl Ruby wrapper]((https://github.com/layer8x/youtube-dl.rb/network)).
4. Manualy terminate converter instances on [EC2 dashboard](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#).  This will cause AWS ELB to fetch latest gems and recreate the converter instances.
5. SSH into AWS converter instances and monitor converions for error message traceback in terminal output.

### Youtube-dl basics
Install youtube-dl on local for unix:
```sh
sudo wget https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl
```
Formats of video available:
```sh
youtube-dl gvdf5n-zI14 --list-formats
```
Download MP4 master video format:
```sh
youtube-dl [ytid] -f best --recode-video mp4
```

### FFMPEG
Conversion from MP4 to [format]
```sh
ffmpeg -y -i [filename].mp4 [output_filename].[format]
```
Conversion from MP4 to [format] and cropping the audio from start time 0 seconds to end time 60 seconds
```sh
ffmpeg -y -i [filename].mp4 -ss 0 -t 60 [output_filename].[format]
```
Conversion from MP4 to 3GP
```sh
ffmpeg -i [filename].mp4 -f 3gp -vcodec h263 -vf scale=1408x1152 -acodec amr_nb -ar 8000 -ac 1 -b:v 12.20k -b:a 12.20k [output_filename].3gp
```
Conversion from MP4 to 3GP and cropping the video from start time 0 seconds to end time 5 seconds
```sh
ffmpeg -i [filename].mp4 -f 3gp -vcodec h263 -vf scale=1408x1152 -acodec amr_nb -ar 8000 -ac 1 -b:v 12.20k -b:a 12.20k -ss 0 -t 5 [output_filename].3gp
```

### Conversion limitations
Guest users & members without active subscription conversions are limited using both Evercookie and IP tracking.

Figaro ENV variables for guest conversion limitations:
```
GUEST_SKIP_DELAY_COUNTDOWN_LIMIT: "3"
GUEST_SKIP_SIGNUP_REQUIRED_MODAL_LIMIT: "2"
GUEST_VIDEO_CONVERSION_LIMIT: "5"
GUEST_VIDEO_DURATION_LIMIT_MINUTES: "6"
GUEST_DELAY_COUNTDOWN_SECONDS: "30"
```
In `Video` model, `authorized_to_download?` and `guest_download_limit_reached?` methods are used to perform the `download limit` and `ip address spoofing` check.

**LOGIC USED:** Video conversion request is made --> the request remote IP address is checked to see if video conversion limit reached:
  1.  Yes --> request denied & `<download_limit> reached` error message displayed
  2.  No --> In `download` method present in `VideosController`, `evercookie` is checked:
      1.  Not set --> set evercookie using the key `guest_uid`, request processed and video served for download
      2.  Set --> but app is unable to find IP in `converted_videos` table, will treat as IP spoofing --> request denied & `<download_limit> reached` error message displayed

## Payments
Stripe is used to handled payments via the [Payola gem](https://github.com/payolapayments/payola)
* Environment variables `STRIPE_PUBLISHABLE_KEY` and `STRIPE_SECRET_KEY` can be retrieved from within the [API key section of Stripe dashboard](https://dashboard.stripe.com/account/apikeys)
* Environment variable `STRIPE_SIGNING_SECRET` can be retrieved from within the [webhooks section of Stripe dashboard](https://dashboard.stripe.com/account/webhooks) (click the webhook to see it's signing secret)
* current Stripe API version is 2018-11-08 (old version 2017-06-05)
* [StripeEvent gem](https://github.com/integrallis/stripe_event) handles Stripe webhook integration

## Testing
Create `.rspec` file in root folder & add:
```
--color
--require spec_helper
--require rails_helper
--format documentation
```
Run all specs:
```
bundle exec rspec spec
```
Run only gateways specs:
```
bundle exec rspec spec/gateways
```
Run only model specs:
```
bundle exec rspec spec/models
```
Run only specs for Member model:
```
bundle exec rspec spec/models/member_spec.rb
```
Run only spec on line 8 of Member model:
```
bundle exec rspec spec/models/member_spec.rb:8
```
All the stripe mock test cases should be defined with `live: true` inline. To toggle stripe-ruby-mock gem to live mode (defined `live: true`) for all test cases:
```
bundle exec rspec -t live
```
## Miscellaneous

### Proxy IP (not used as of March 19, 2018 since AWS ELB can rotate IP's by scheduling instances)
To enable proxies, please edit `credentials.yml.enc` (`EDITOR=vi bin/rails credentials:edit`) and set `TINYPROXY_ENABLED` to `true`

**LOGIC USED:**
* After video conversion is started, the `build_options()` method is invoked.  In the `build_options()` method, while generating the options hash, the `get_proxy` method present in `Tinyproxy` is invoked to fetch the proxy IP.
* The proxy IPs we use for video conversion, these IPs are the private IP of the two aws instances `gafv-tinyproxy-1` and `gafv-tinyproxy-2`.
* While fetching a proxy IP, following conditions are checked and if a proxy IP meets any one of the conditions mentioned below then we perform the proxy IP rotation and that proxy IP will be released:
  * If it as meet the minutes limit defined in `Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_USAGE_MINUTES]`
  * If total no.of request made using a proxy IP reached the limit defined in `Rails.application.credentials[Rails.env.to_sym][:TINYPROXY_REQUEST_LIMIT]`

* **Proxy IP rotation:**
  Suppose if we are using the IP of the instance `gafv-tinyproxy-1` and if it has met any of the condition mentioned above in point (a) and point (b) then `get_proxy` method will return the public IP of the instance `gafv-tinyproxy-2`.

* **Release current IP and attach new IP:**
  Let's consider the public IP of instance `gafv-tinyproxy-1` has met a condition mentioned above in point (a) and point (b) then the current IP associated with the instance `gafv-tinyproxy-1` will be disassociated and a new IP address will be assigned to the instance `gafv-tinyproxy-1` and the disassociated IP will be released.

* When a request is made using a proxy if the request is failed due to the error `unable to download webpage`. In this case, the conversion is tried again with new proxy & will repeat until `Rails.application.credentials[Rails.env.to_sym][:PROXY_RETRY_LIMIT]` reached.
