#!/usr/bin/env node
import getAuth from './Auth.js'
import axios from 'axios'
import yargs from 'yargs'
import path from 'path'

// create a yargs command line interface to support multiple subcommands e.g. DownloadPR, ListPR etc.
// and options like project name
// e.g. node ado.js listpr --project office
// e.g. node ado.js downloadpr --project office --pr 123
// e.g. node ado.js listpr --project office --status active
// e.g. node ado.js listpr --project office --status completed
// e.g. node ado.js listpr --project office --status abandoned
// e.g. node ado.js listpr --project office --status all
// e.g. node ado.js listpr --project office --status active --creator "John Doe"
// e.g. node ado.js listpr --project office --status active --creator "John Doe" --target "main"
// also provide bash completion
const argv = yargs(process.argv.slice(2))
.command('downloadpr', 'Download Pull Request', (yargs) => {
	yargs.option('project', {
		alias: 'p',
		describe: 'Project Name',
		type: 'string',
		default: 'office'
	})
	.option('pullRequestId', {
		alias: 'id',
		describe: 'Pull Request ID',
		type: 'number',
		demandOption: true
	})
	.option('repository', {
		alias: 'r',
		describe: 'repository name',
		default : 'office',
		type: 'string',
	})
	.option('status', {
		alias: 's',
		describe: 'Status of PR comments',
		type: 'string',
		choices: ['active', 'all'],
		default: 'active'
	})
})
.command('listpr', 'List Pull Requests', (yargs) => {
	yargs.option('project', {
		alias: 'p',
		describe: 'Project Name',
		default : 'office',
		type: 'string',
	})
	.option('repository', {
		alias: 'r',
		describe: 'repository name',
		default : 'office',
		type: 'string',
	})
	.option('status', {
		alias: 's',
		describe: 'Status of PR',
		type: 'string',
		choices: ['active', 'completed', 'abandoned', 'all'],
		default: 'active'
	})
	.option('creator', {
		alias: 'c',
		describe: 'Creator of PR',
		type: 'string'
	})
	.option('reviewer', {
		describe: 'Reviewer of PR',
		type: 'string'
	})
	.option('target', {
		alias: 't',
		describe: 'Target Branch',
		type: 'string'
	})
})
.example('node $0 downloadpr --project office --status all --pullRequestId 2777289', 'Download all comments for PR 2777289')
.wrap(140)
.demandCommand(1, 'You need at least one command before moving on')
.help()
.parse()




// create ADO class which configures a axios instance with the token
// and provides methods to make requests to ADO
class ADO {
	// constructor variable number of dictionary parameters
	constructor(organization, project) {
		this.auth = getAuth();
		this.axios = axios.create({
			baseURL: `https://dev.azure.com/${organization}/${project}`,
			// no timeout
			timeout: 0,
			headers: {
                'User-Agent' : 'Microsoft ADO Node.js Client',
				'Content-Type': 'application/json'
			}
		});
	}

	async request(url, config) {
		const token = await this.auth.getToken();
		this.axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
		return this.axios.request(url, config);
	}

	// write methods to request all comments from a PR
	async getComments(repository, pullRequestId) {
		const url = `_apis/git/repositories/${repository}/pullRequests/${pullRequestId}/threads?api-version=7.1-preview.1`;
		const response = await this.request(url);
		return response.data;
	}
};



// create an ADO object
const ado = new ADO('office', argv.project);

// if downloadpr command and PR id is given, then get all comments for the PR. And filter the comments based on status
if (argv._.includes('downloadpr') && argv.pullRequestId) {
	(async () => {
		const comments = await ado.getComments(argv.repository, argv.pullRequestId);
		// iterate over comments and filter based on status
		for (const commentThread of comments.value) {
			const commentStatus = commentThread?.status ?? "unknown";
			if (argv.status !== 'all' && (commentStatus !== 'active' && commentStatus !== 'pending')) {
				continue;
			}
			if (commentThread?.comments?.[0].commentType === 'system') {
				continue;
			}
			const threadcontext = commentThread?.threadContext;
			if (!threadcontext) {
				// TODO : print comments without threadContext. These are 
				// applicable over whole PR.
				continue;
			}
			const filepath = threadcontext.filePath;
			const startLine = threadcontext.rightFileStart?.line ?? 0;
			const endLine = threadcontext.rightFileEnd?.line ?? 0;
			console.log(`.${filepath}:${startLine}:(${commentStatus}) --  `);
			for (const comment of commentThread?.comments) {
				const author = comment.author.displayName;
				const content = comment.content;
				console.log(`->(${author}): ${content}`);
			}
		}
	})();
}
