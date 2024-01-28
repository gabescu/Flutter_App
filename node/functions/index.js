const os = require('os');
const fs = require('fs');
const path = require('path');

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const bucket = admin.storage().bucket('gs://clientservercommands.appspot.com');
const UUID = require("uuid-v4");
const fcm = admin.messaging();
const firestoreDb = admin.firestore();

const version = "1.0.0";

const OPERATION_STATUS = {
    COMPLETED: 1,
    ERRORED: 2,
};

function millisToMinutes(millis) {
    return Math.floor(millis / 60000);
}

exports.Version = functions.https.onRequest(async (req, res) => {
    res.send(`Current version: ${version} as of ${new Date()}`);
});

exports.sendClientCommand = functions.https.onCall(async (data, context) => {
    return new Promise(async (resolve, reject) => {
        try {
            let action = data.action;
            let serverToken = data.serverToken;
            let clientToken = data.clientToken;
			let commandId = data.commandId;

            const payload = {
                notification: {
                    title: 'ACTION',
                    body: 'Client Action'
                },
                data: {
					commandId: commandId,
                    action: action,
                    clientToken: clientToken
                }
            };
            const options = {
                priority: "high",
                collapseKey: "client_action"
            };
            let devicesResponse = await fcm.sendToDevice(serverToken, payload, options);

            return resolve({
                DATA: devicesResponse.results,
                STATUS: OPERATION_STATUS.COMPLETED
            });
        } catch (e) {
            return resolve({
                DATA: e.code,
                STATUS: OPERATION_STATUS.ERRORED
            });
        }
    });
});

exports.returnConfirmation = functions.https.onCall(async (data, context) => {
    return new Promise(async (resolve, reject) => {
        try {
            let response = data.response;
            let responseType = data.responseType;
            let clientToken = data.clientToken;

            const payload = {
                notification: {
                    title: 'RESPONSE',
                    body: 'Server Response'
                },
                data: {
                    response: responseType,
                    output: response.toString()
                }
            };
            const options = {
                priority: "high",
                collapseKey: "server_response"
            };
            let devicesResponse = await fcm.sendToDevice(clientToken, payload, options);

            return resolve({
                DATA: devicesResponse.results,
                STATUS: OPERATION_STATUS.COMPLETED
            });
        } catch (e) {
            return resolve({
                DATA: e.code,
                STATUS: OPERATION_STATUS.ERRORED
            });
        }
    });
});

exports.returnImage = functions.https.onCall(async (data, context) => {
    return new Promise(async (resolve, reject) => {
        try {
            let response = data.response;
            let responseType = data.responseType;
            let clientToken = data.clientToken;

            let buffer = new Buffer(response, 'base64');
            let outputDocName = `image.jpg`;
            let absoluteOutputPath = path.resolve(os.tmpdir(), outputDocName);

            let uploadUUID = UUID();
            fs.writeFileSync(absoluteOutputPath, buffer);

            let uploadResponse = await bucket.upload(absoluteOutputPath, {
                destination: outputDocName,
                uploadType: "media",
                resumable: false,
                metadata: {
                    metadata: {
                        firebaseStorageDownloadTokens: uploadUUID
                    }
                }
            });

            fs.unlinkSync(absoluteOutputPath);
            let file = uploadResponse[0];
            let fileDownloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${uploadUUID}`;

            return resolve({
                DATA: fileDownloadUrl,
                STATUS: OPERATION_STATUS.COMPLETED
            });
        } catch (e) {
            return resolve({
                DATA: e.code,
                STATUS: OPERATION_STATUS.ERRORED
            });
        }
    });
});

exports.ClearServers = functions.pubsub.schedule('0 * * * 7').onRun(async (context) => {
    let serverCollection = await firestoreDb.collection("servers");
    let serverDocs = await serverCollection.get();
    let deletePromises = [];
    let keepAliveDuration = 120; //120 minutes
    serverDocs.forEach((serverDoc) => {
        let serverData = serverDoc.data();
        let lastKeepAlive = serverData["keepalive"].toDate();
        let now = new Date();
        let minutesDiff = millisToMinutes(Math.abs(lastKeepAlive - now));
        if (minutesDiff > keepAliveDuration) {
            functions.logger.log(`Deleting ${serverDoc.id}`, minutesDiff.toString());
            deletePromises.push(serverCollection.doc(serverDoc.id).delete());
        }
    });
    await Promise.all(deletePromises);
});