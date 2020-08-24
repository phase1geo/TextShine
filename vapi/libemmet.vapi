[CCode (cprefix = "emmet")]
namespace Emmet {

    [Compact]
    [CCode (cheader_filename = "mkdio.h", cname = "MMIOT", free_function = "mkd_cleanup")]
    public class Text {

        [CCode (cname = "mkd_string")]
        public Text.parse( uint8[] data, int flag = 0 );

    }
}
