/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-02-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   10-02-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
public class CustomNotesComponentCtrlTest {
    @isTest static void TestMethod1(){
        Account TestAcc = new Account();
        TestAcc.Name = 'TestAcc';
        Insert TestAcc;
        List<ContentNote> testnots = CreateNotes(TestAcc.Id);
        test.startTest();
        	CustomNotesComponentCtrl.getEnhancedNotes(TestAcc.Id);
        	CustomNotesComponentCtrl.getCurrentUserInfo();
        	CustomNotesComponentCtrl.createRecord('This is testing descritpion', TestAcc.Id);
        	CustomNotesComponentCtrl.updateContentNotes(testnots[0].Id, 'This is testing body');
        	CustomNotesComponentCtrl.delContentNote(testnots[0].Id);
        	CustomNotesComponentCtrl.getObjectName(TestAcc.Id);
        test.stopTest();
    }
    private static List<ContentNote> CreateNotes(String ObjId){
        list<ContentDocumentLink> DocsToInsert = new list<ContentDocumentLink>();
        list<ContentNote> NotesToAdd = new list<ContentNote>();
        for(integer i=0; i<1; i++){
            ContentNote objCntNote = new ContentNote();
            objCntNote.Title = 'salesforce code crack';
            objCntNote.Content = Blob.valueOf('Welcome to salesforcecodecrack.com');
            NotesToAdd.add(objCntNote); //Insert Content Note   
            Insert objCntNote;
            //create ContentDocumentLink  record to link with parentId 
            ContentDocumentLink objCntDocLink = new ContentDocumentLink();
            objCntDocLink.LinkedEntityId = ObjId; // Specify your parent Id 
            objCntDocLink.ContentDocumentId = objCntNote.Id;  //Content Note Id
            objCntDocLink.shareType = 'V'; // Specify your sharing type
            DocsToInsert.add(objCntDocLink);
        }
        if(DocsToInsert.size() > 0){
            insert DocsToInsert;
        }
        return NotesToAdd;
    }
}