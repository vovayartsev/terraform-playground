require 'roda'
require 'aws-sdk'

class App < Roda
  route do |r|
    r.root do
      begin
        s3 = Aws::S3::Resource.new(region: 'us-east-1')
        bucket = s3.bucket(ENV.fetch('BUCKET_NAME'))
        bucket.object('hello.txt').get.body.read
      rescue
        $!.message
      end
    end
  end
end

run App.freeze.app
