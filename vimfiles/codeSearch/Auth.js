import child_process from 'node:child_process'
// import authConfig from './authConfig.json' assert { 'type' : 'json'}



class Authentication
{
    async getToken() { 
        throw new Error("Authenticator not derived");
    }
};

class AzureAuth extends Authentication
{
    constructor() {
        super();
        this.tokenCache = null;
    }

    async getToken() 
    {
        // lookup from cache
        if (this.tokenCache) {
            const expiry = new Date(this.tokenCache.expiresOn);
            if (expiry > Date.now()) {
                // still valid
                return this.tokenCache.accessToken;
            }
        }
        const out = child_process.execSync('az account get-access-token')
        this.tokenCache = JSON.parse(out.toString());
        return this.tokenCache.accessToken;
    }
};

export default function getAuth() {
	// const config = authConfig;
	//TODO: use config to create appropriate Auth class object
    return new AzureAuth();
}

