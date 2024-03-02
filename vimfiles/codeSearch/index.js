#!/usr/bin/env node
import fs from 'node:fs'
import getAuth from './Auth.js'
import axios from 'axios'
import yargs from 'yargs'
import path from 'node:path'
import qs from 'node:querystring'
import fetch from 'node-fetch'


const auth = getAuth(); // todo to extend in future

// TODO : implement a ls subcommand to query directories files in scope
const cli = yargs(process.argv.slice(2))
	.option("debug", {
		describe : "debug run",
		default : false,
		type : "boolean"
	})
    .option("scope", {
        alias : "s",
        describe : "Scope path of search",
        default : "/word",
        defaultDescription : "/word",
        type : "string"
    })
    .option("officeDir", {
        alias : ["o"],
        describe : "path to office enlistment src-folder",
        default : process.cwd(),
        defaultDescription : "current working dir",
        type : "string"
    })
    .option("downloaddir", {
        alias : ["cachedir", "c"],
        describe : "path to directory where to download the files, if needed",
        default : process.cwd(),
        defaultDescription : "current working dir",
        type : "string"
    })
    .option("top", {
        alias: "t",
        describe : "limit to top <n> results",
        default : 50,
        type : "number"
    })
    .option("download", {
        alias : "d",
        describe : "download files to cache-dir",
        default : true,
        boolean : true
    })
    .option("project", {
        alias : "p",
        describe : "project to search in",
        default : "office",
		type : "string"
    })
    .option("repository", {
        alias : "r",
        describe : "repo name to search in",
        default : "office",
		type : "string"
    })
    .option("branch", {
        alias : "b",
        describe : "branch name to search in",
        default : "main",
		type : "string"
    })
    .help("help")
    .alias("help", ["h", "?"])
    .coerce("downloaddir", (dd) => {
        return path.isAbsolute(dd) ? dd : path.join(process.cwd(), dd);
    })
    .check((argv, options) => {
        if (argv._.length != 1)
            return "Only single search-text/pattern could be provided per query"
        if (argv.scope[0]  != "/")
            return "Scope should start with /, e.g. /word";
        if (argv.d == true)
        {
            try {
                fs.accessSync(argv.officeDir, fs.constants.W_OK | fs.constants.R_OK); // will throw, if fail
                fs.accessSync(argv.downloaddir, fs.constants.W_OK | fs.constants.R_OK); // will throw, if fail
            } catch (err) {
                return err.message;
            }
        }
        return true;
    })
    .example([
        ['$0 <search-text|pattern>'],
        ['$0 -d -c D:/office/reSearchCache <search-text|pattern> -t 20', "Search pattern and return top 20 matches, downloading files to cache"],
    ])
    .wrap(140)
    .parse();


const cacheDirPath = (() => {
	if (cli.debug)
		return path.join(cli.cachedir, 'reSearchCache'); // TODO remove join
	else
		return cli.cachedir;
})();


class Query
{
    // doc : https://learn.microsoft.com/en-us/rest/api/azure/devops/search/code-search-results/fetch-code-search-results?view=azure-devops-rest-6.1&tabs=HTTP
    constructor() {
            this.queryObj = {
            "searchText": "",
            "$skip": 0,
            "$top": 20,
            "filters": {
                "Project": ["office"],
                "Repository": ["office"],
                "Path": ["/word"],
                "Branch": ["main"],
                //"CodeElement": ["def"]
            },
            "$orderBy": null,
            "includeFacets": false
        };
    }

    set top(val) { 
        this.queryObj.$top = val;
    }
    get top() {
        return this.queryObj.$top;
    }
    set searchText(val) {
        this.queryObj.searchText = val;
    }
    get searchText() { 
        return this.queryObj.searchText;
    }

    set project(val) {
        this.queryObj.filters.Project = [`${val}`];
    }

    get project() {
        return this.queryObj.filters.Project?.[0];
    }

    set repository(val) {
        this.queryObj.filters.Repository = [`${val}`];
    }

    get repository() {
        return this.queryObj.filters.Repository?.[0];
    }

    set branch(val) {
        this.queryObj.filters.Branch = [`${val}`];
    }

    get branch() {
        return this.queryObj.filters.Branch?.[0];
    }

    set scope(val)  { 
        this.queryObj.filters.Path = [`${val}`]
    }

    get scope() { 
        return this.queryObj.filters.Path?.[0];
    }

    async searchRestClient() {
        const token = await auth.getToken();
        const clientConfig = {
            baseURL : `https://almsearch.dev.azure.com/office/_apis/search`,
            headers : {
                'User-Agent' : 'Microsoft ReSearch',
                'Content-Type' : 'application/json',
                'X-TFS-FedAuthRedirect' : 'Suppress',
                'Authorization' : `Bearer ${token}`
            }
        };
        return axios.create(clientConfig);
    }

    async search() {
        try {
            const restClient = await this.searchRestClient();
            const {data} = await restClient.post('/CodeSearchResults?api-version=7.0', this.queryObj);
            return data;
        }catch(err)
        {
            console.error(err);
        }
    }

    async gitRestClient(project) {
        const token = await auth.getToken();
        const clientConfig = {
            baseURL : `https://office.visualstudio.com/${project}/_apis/git`,
            headers : {
                'User-Agent' : 'Microsoft ReSearch',
                'Content-Type' : 'application/json',
                'Authorization' : `Bearer ${token}`
            }
        };
        return axios.create(clientConfig);
    }


    async downloadFile(rd) {

        //  var url = $"{repoGitApiUri.AbsoluteUri}items?versionType={changeIdType}&version={changeId}&scopePath={HttpUtility.UrlEncode(path)}&api-version=3.0";
        // https://office.visualstudio.com/Office/items?versionType
        if (rd.repository.type == "git")
        {
            try {
                const uri = `https://office.visualstudio.com/${rd.project.name}/_apis/git`
                    + '/repositories/'
                    + `${rd.repository.id}/items?`
                    + qs.encode({
                        scopePath: rd.path,
                        versionType: ((rd.versions[0].changeId) ? "commit" : "branch"),
                        version: ((rd.versions[0].changeId) ? rd.versions[0].changeId : rd.versions[0].branchName),
                        "api-version": "6.1-preview.1"
                    });
                const token = await auth.getToken();
                const options = {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                };
                const content = await (await fetch(uri, options)).text();
                return content;
            } catch (err)
            {
                console.error(err);
            }
        }else
        {
            const uri = '/customCode?' + qs.encode({
                projectName: this.project,
                repositoryName: rd.repository.name,
                branchName: rd.contentId,
                filepath: rd.path,
                "api-version": "6.0-preview.1"
            });
            try {
                const restClient = await this.searchRestClient();
                const {data} = await restClient.get(uri);
                return data;
            } catch (err) {
                console.errort (err);
            }
        }
    }
};

function saveFile(fpath, content) {
    const fullPath = path.join(cacheDirPath, fpath);
    const dirpath = path.dirname(fullPath);
    // make director to save
    try {
        fs.mkdirSync(dirpath, { recursive: true });
    } catch (err) { }
    // check access to director
    try {
        fs.accessSync(dirpath, fs.constants.R_OK | fs.constants.W_OK);
    } catch (err) {
        console.error(err);
    }
    try {
        const fd = fs.openSync(fullPath, 'w');
        fs.writeFileSync(fd, content);
        fs.close(fd);
    } catch (err) {
        console.error(err);
    }
    return fullPath;
}

class DownloadedFileDb
{
    constructor() {
        this.cacheDirPath = cacheDirPath;
        this.dbPath = path.join(this.cacheDirPath, "downloadedFileDb.json");
        try { 
            fs.accessSync(this.dbPath, fs.constants.R_OK | fs.constants.W_OK);
            this.dbMap = new Map(JSON.parse(fs.readFileSync(this.dbPath)));
        } catch(err)
        {
            this.dbMap = new Map();
        }
    }

    record(fpath, changeId) { 
        this.dbMap.set(fpath, changeId);
    }

    exist(fpath, changeId) { 
        try {
            if (this.dbMap.get(fpath) == changeId) {
                const fullPath = path.join(this.cacheDirPath, fpath);
                fs.accessSync(fullPath, fs.constants.R_OK);
                return true;
            }
        }catch(err)
        {
            return false;
        }
    }

    content(fpath) {
        try {
            const fullPath = path.join(this.cacheDirPath, fpath);
            const content = fs.readFileSync(fullPath).toString();
            return { fullPath , content};
        } catch(err)
        {
            console.error(err);
        }
    }

    saveDb() {
        try {
            const content = JSON.stringify(Array.from(this.dbMap.entries()));
            fs.writeFileSync(this.dbPath, content);
        } catch(err)
        {
            console.error(err);
        }
    }
}

class OfficeEnlistment
{
    constructor() {
        this.officeDir = cli.officeDir;
    }

    exist(fpath){
        const fullPath = path.join(this.officeDir, fpath);
        try {
            fs.accessSync(fullPath, fs.constants.R_OK);
            return true;
        }catch(err)
        {
            return false;
        }
    }

    content(fpath) {
        try {
            const fullPath = path.join(this.officeDir, fpath);
            const content = fs.readFileSync(fullPath).toString();
            return { fullPath , content};
        } catch(err)
        {
            console.error(err);
        }
    }
}

function inspectInfoCode(code) {
    if (code == 0) return;
    if (code == 2) console.error('Account indexing has not started');
    if (code == 3) console.error('Invalid Request');
    if (code == 4) console.error('Prefix wildcard query not supported');
    if (code == 5) console.error('MultiWords with code facet not supported');
    if (code == 6) console.error('Account is being onboarded');
    if (code == 7) console.error('Account is being onboarded or reindexed');
    if (code == 8) console.error('Top value trimmed to maxresult allowed 9 - Branches are being indexed');
    if (code == 10) console.error('Faceting not enabled');
    if (code == 11) console.error('Work items not accessible');
    if (code == 19) console.error('Phrase queries with code type filters not supported');
    if (code == 20) console.error('Wildcard queries with code type filters not supported.');
    else 
    {
        // Any other info code is used for internal purpose.
    }
}


try {
    (async () => {
        const q = new Query();
        const db = new DownloadedFileDb();
        const enlistment = new OfficeEnlistment();
        q.searchText = cli._[0];
        q.scope = cli.scope;
		q.project = cli.project;
		q.repository = cli.repository;
		q.branch = cli.branch;
        q.top = cli.top;
        let data = await q.search();
        inspectInfoCode(data.infoCode);
        for (let r of data.results) {
            let content = null;
            let fullPath = null;
            if (enlistment.exist(r.path)) {
                // exists in enlistment
                const c = enlistment.content(r.path);
                content = c.content;
                fullPath = c.fullPath;
            } else if (db.exist(r.path, r.versions[0].changeId)) {
                // exist in cache
                const c = db.content(r.path);
                content = c.content;
                fullPath = c.fullPath;
            } else {
                // need to download
                content = await q.downloadFile(r);
                fullPath = saveFile(r.path, content);
                db.record(r.path, r.versions[0].changeId);
            }
            const contentLineArr = content.split("\n");
            let sz = 0;
            const contentLineEndOffset = contentLineArr
                .map(line => line.length + 1)
                .map(len => sz += len);
            r.matches.content.map(m => {
                const line = contentLineEndOffset.filter(eOffset => m.charOffset > eOffset).length + 1;
                const lineContent = contentLineArr[line - 1];
                // output fmt
                // filepath:line:line content
                console.log(`${fullPath}:${line}:${lineContent}`);
            });
			if (r.matches.content.length == 0)
			{
				// could happen for file:<filename> lookups
				console.log(`${fullPath}:1:${contentLineArr[0]}`);
			}
        }
        db.saveDb();
    })();
} catch (err)
{
    console.error(err);
}
