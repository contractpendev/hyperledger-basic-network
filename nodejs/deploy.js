/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
const path = require('path');
const fs = require('fs');

const { Template } = require('@accordproject/cicero-core');
const { Clause } = require('@accordproject/cicero-core');

const api = require('./api');
const config = require('./config.json');

const deploy = async () => {
  const archivePath = path.resolve(process.argv[2]);
  const samplePath = path.resolve(process.argv[3]);

  const template = await Template.fromArchive(fs.readFileSync(archivePath));
  const archive = await template.toArchive('javascript');
  const templateBase64 = archive.toString('base64');
  const clauseText = fs.readFileSync(samplePath, 'utf8');

  // parse the contract text
  const clause = new Clause(template);
  clause.parse(clauseText);
  const clauseData = clause.getData();
  console.log('clause data');
  console.log(clauseData);

  const clauseData2 = { '$class': 'org.accordproject.helloworld.HelloWorldClause',
  clauseId: '3f645857-d099-4f60-947d-75051df363e9',
    name: 'Fred Blogs' };

  
const request = {
    fcn: 'deploySmartLegalContract',
    args: [/*config.contractId*/ process.argv[4], templateBase64, JSON.stringify(clauseData2)],
  };

  return api.proposeAndCommitTransaction(request);
};

deploy();
