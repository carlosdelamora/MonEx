const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });


exports.updateStatus = functions.database.ref('/bidIdStatus/{bidIdStatus}').onWrite( event => {

     const snapshot = event.data.val();
     const authorOfTheBidFirebaseId = snapshot.authorOfTheBid;
     const theOtherUserFirebaseId = snapshot.otherUser;
     const status = snapshot.status;
     const bidId = snapshot.bidId;
     const lastOneToWrite = snapshot.lastOneToWrite;
     console.log('status is', status );
     const pathForAuthor = '/Users/' + authorOfTheBidFirebaseId + '/Bid/' + bidId;
     const pathForTheOther = '/Users/' + theOtherUserFirebaseId + '/Bid/' + bidId;

     if (status !== 'active' && status !== 'halfComplete'){
         updateStatus(pathForAuthor,status);
         updateStatus(pathForTheOther, status);
     };

     if( status === 'halfComplete'){
         const updateToComplete = (lastOneToWrite === authorOfTheBidFirebaseId) ? pathForAuthor: pathForTheOther;
         const updateToHalfComplete = (lastOneToWrite !== authorOfTheBidFirebaseId) ? pathForAuthor: pathForTheOther;
         updateStatus(updateToComplete, "complete");
         updateStatus(updateToHalfComplete, "halfComplete");
     };

     return ;
});

function updateStatus(path, estatus){
  console.log('path',path, ',estatus', estatus);
   return admin.database().ref(path).update({'/offer/offerStatus':estatus}).then(function(response){
      console.log(response, Object.prototype.toString.call(response));

   }).catch(function(error){
     console.log(error, Object.prototype.toString.call(error));
   });
}
