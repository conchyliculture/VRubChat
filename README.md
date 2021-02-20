# VRubChat

## Usage

You'll probably need to `apt install ruby-curb` first.

Copy `config.json.template` into `config.json` and add your credentials.

Just run `ruby vrubchat.py` to see if any of your friends are online on VRChat.

## Troubleshoot

If the script stops running, it might be because the API key was rotated.
The script uses `JlE5Jldo5Jibnk5O5hTx6XVqsJu4WJ26`, which is the API key that the JS uses in your web browser when you log in via vrchat.com

You can hopefully get the new one by running:

```
curl -s "https://vrchat.com/client/home/public/index.js" | ruby -e "puts ARGF.read()[/window.apiKey=\"([^\"]+)\"/,1]"
```

and change it in config.json
