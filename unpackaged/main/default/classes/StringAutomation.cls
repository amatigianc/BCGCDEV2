public class StringAutomation {

@InvocableMethod(label='RemoveHTMLTags')
public static List<String> removeHTMLTags(List<String> richTextList) {
String richText = richTextList[0];

List<String> plainTextList = new List<String>();

richText = richText.StripHTMLTags();

plainTextList.add(richText);
return plainTextList;

}


}