const AWS = require('aws-sdk');
const cloudfront = new AWS.CloudFront();

exports.handler = async(event) => {
    // Extract the Job ID
    console.log('event:', event);
    const job_id = event['CodePipeline.job']['id'];

    // Extract the Job Data
    const job_data = event['CodePipeline.job']['data'];
    console.log('job_data:', job_data);

    const params = {
        DistributionId: 'E1UI4WO3UOYAEE',
        InvalidationBatch: {
            CallerReference: `invalidate-after-s3-${new Date().getTime()}`,
            Paths: {
                Quantity: 1,
                Items: ['/*']
            }
        }
    };
    await cloudfront.createInvalidation(params).promise();

    var codepipeline = new AWS.CodePipeline();
    await codepipeline.putJobSuccessResult({
        jobId: job_id,
    }).promise();

    // TODO implement
    const response = {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!'),
    };
    return response;
};
