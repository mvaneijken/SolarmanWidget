class Conversion {

    function StringToByteArray(plain_text) {
        return StringUtil.convertEncodedString(plain_text, {
            :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
            :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
            :encoding => StringUtil.CHAR_ENCODING_UTF8
        });
    }

    function ByteArrayToHexString(byte_array) {
        return StringUtil.convertEncodedString(byte_array, {
            :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
            :toRepresentation => StringUtil.REPRESENTATION_STRING_HEX,
            :encoding => StringUtil.CHAR_ENCODING_UTF8
        });
    }

    function ByteArrayToBase64String(byte_array) {
        return StringUtil.convertEncodedString(byte_array, {
            :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
            :toRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
            :encoding => StringUtil.CHAR_ENCODING_UTF8
        });
    }

    function Utf8ArrayToString(utf8Array) {
        return StringUtil.utf8ArrayToString(utf8Array);
    }
}

class Hash {

        function NewSha256HashObject() {
        return new Cryptography.Hash({
            :algorithm => Cryptography.HASH_SHA256
        });
    }

    function ComputeHash(hash, byte_array) {
        hash.update(byte_array);
        return hash.digest();
    }
}