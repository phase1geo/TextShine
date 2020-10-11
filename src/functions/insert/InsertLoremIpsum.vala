/*
* Copyright (c) 2020 (https://github.com/phase1geo/TextShine)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*
* SPECIAL NOTE:  The lorem ipsum that is generated came from https://www.lipsum.com
*                created by James Wilson.
*/

using Gtk;

public class InsertLoremIpsum : TextFunction {

  private int           _paragraphs;
  private Array<string> _lorem;

  /* Constructor */
  public InsertLoremIpsum() {
    base( "insert-lorem-ipsum" );
    _paragraphs = 1;
    _lorem = new Array<string>();
    _lorem.append_val( "Etiam ultricies libero vel cursus dapibus. Morbi bibendum erat eget orci feugiat, vel consectetur massa consequat. Praesent facilisis tempus gravida. Nullam quis massa id tortor maximus varius. Quisque eu luctus nisl. Curabitur suscipit congue varius. Aliquam facilisis, nunc at facilisis pretium, nulla risus venenatis odio, in elementum libero metus sed lectus." );
    _lorem.append_val( "Morbi in efficitur velit. Phasellus varius tellus et turpis viverra sollicitudin. Suspendisse maximus dictum est varius iaculis. Pellentesque euismod euismod iaculis. Sed mattis leo porta, mollis neque vel, vulputate tortor. Proin turpis tellus, efficitur et porttitor ut, consequat id urna. Aliquam ornare iaculis rutrum. Phasellus eu leo lobortis, tempus magna sit amet, cursus dolor. Nullam viverra quis elit eget ultrices. Aliquam tincidunt sed sem eu porttitor." );
    _lorem.append_val( "Mauris pretium ipsum at lacus suscipit euismod. Nunc massa sapien, tincidunt a facilisis vitae, volutpat ut quam. Vestibulum viverra pellentesque ipsum non pretium. Proin faucibus lacinia ligula. Aenean nec augue non orci mollis luctus. Nullam felis felis, posuere sit amet felis sed, sagittis ullamcorper dui. Donec consectetur ultricies tellus sit amet lobortis." );
    _lorem.append_val( "Nam mauris dui, vehicula sit amet luctus non, dignissim nec metus. Sed accumsan leo ut pellentesque commodo. Nullam vitae convallis ligula, posuere ornare nisi. Pellentesque sed ex est. Donec tristique faucibus elementum. Nullam tempor placerat leo, id dignissim eros ullamcorper ac. Curabitur a posuere elit. Aliquam iaculis velit ac pulvinar congue. Donec arcu orci, pulvinar et justo non, bibendum rhoncus dolor. Etiam efficitur ante sapien, elementum fringilla risus viverra quis. Maecenas lacinia in ex eu malesuada." );
    _lorem.append_val( "Suspendisse nec tincidunt erat, non congue purus. Maecenas fringilla ultricies fermentum. Vestibulum rutrum ex magna, eget facilisis nulla hendrerit ut. In mi ipsum, tristique eget porta ac, ornare at nisl. Nulla volutpat feugiat placerat. Nullam neque sapien, rhoncus non est eu, lobortis facilisis quam. Quisque id pulvinar nulla, non consequat erat. Aenean vel massa sagittis, rutrum ipsum sit amet, tempus eros. Nam vitae euismod leo. Donec molestie augue lorem, vitae molestie nunc dignissim at. Integer sodales, nibh vel efficitur dignissim, felis ante pretium mauris, a malesuada nulla ante in risus. Nulla facilisi. In cursus sodales ipsum vel varius. Ut vel nisl nibh." );
    _lorem.append_val( "Duis bibendum, leo in aliquet varius, enim dolor porttitor neque, iaculis dapibus tellus eros eget justo. Donec iaculis risus et nisl finibus imperdiet. Donec suscipit sollicitudin enim gravida elementum. Morbi vestibulum leo id vehicula elementum. Maecenas sodales sem vel rhoncus faucibus. Nulla leo nisl, viverra a magna ac, ullamcorper tempus est. Vivamus ac ultrices est. Nam consequat mattis egestas. Integer imperdiet lorem sit amet pulvinar consectetur. Integer ut varius velit, eu imperdiet lectus." );
    _lorem.append_val( "Cras cursus risus id nibh placerat, at malesuada purus vestibulum. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vivamus semper erat nec arcu dictum, id suscipit dolor eleifend. Nulla ac ornare ipsum. Pellentesque mollis velit in nulla pharetra vulputate. In ultrices lectus neque, at mollis ipsum semper consequat. Proin fermentum, neque at hendrerit semper, orci nibh ultrices velit, vitae dapibus ex odio id ligula. Suspendisse vulputate, lectus sed mattis dictum, turpis urna euismod dolor, ut porta urna ipsum et sapien. Curabitur a bibendum ante, id tempus dolor. Etiam varius urna et lobortis rutrum. Pellentesque quis ex id erat interdum viverra. Etiam ut tortor et odio iaculis interdum eget ut tellus. Suspendisse vel dictum magna. Duis vehicula metus in nibh lacinia tristique. Morbi vitae ligula erat. Aenean quis vehicula dui." );
    _lorem.append_val( "Donec quis rhoncus risus, vel molestie urna. Quisque ornare magna in nulla tempor porta. Quisque finibus fringilla eros, non imperdiet lectus ullamcorper quis. Proin vulputate metus et nisl ullamcorper eleifend. Sed et orci tellus. Suspendisse potenti. Proin sodales hendrerit justo, a fringilla neque fringilla ac." );
    _lorem.append_val( "Integer faucibus tincidunt ligula, sit amet vehicula magna sodales sed. Aliquam nisl ante, consequat sed condimentum id, vulputate eu ipsum. Integer faucibus ullamcorper metus, at pellentesque lorem tincidunt in. Fusce tempus molestie erat, id ornare nulla. Curabitur ac lacus maximus, convallis nisl vel, tempor justo. Nulla ut luctus ex. Suspendisse sodales ornare facilisis. Vestibulum posuere ac risus eu faucibus. Vestibulum rutrum luctus ipsum in sollicitudin. Aenean eu tellus sed lectus egestas dictum id non nisi. Nunc vulputate venenatis convallis. Etiam ut lorem sit amet ex ultricies volutpat sit amet sit amet nulla. Sed dignissim augue in urna rutrum, nec aliquet orci iaculis." );
    _lorem.append_val( "Suspendisse auctor suscipit quam, sed mattis odio vehicula eget. Phasellus nec elementum quam. Aenean ut egestas felis. Nunc egestas arcu et varius facilisis. Praesent eu tristique ante. Praesent arcu mi, tempus sed lobortis sit amet, sollicitudin ac odio. Mauris at commodo enim, at venenatis enim. Sed non tellus eu massa tristique tristique. Donec urna nunc, vestibulum eget sagittis non, gravida vel mi. Aliquam auctor orci eu orci ornare, vel pellentesque turpis molestie. Sed vulputate ante sit amet dolor lacinia pharetra. Maecenas consectetur molestie est, sit amet porta velit. Cras enim urna, lacinia non nibh a, tristique venenatis nibh. Cras lacinia tempor justo vitae venenatis. Pellentesque rhoncus ligula vulputate tortor sagittis, quis mattis lacus sagittis." );
    _lorem.append_val( "Nulla porta, mi non consequat mattis, est nisi hendrerit neque, non malesuada tellus magna luctus sapien. Quisque vel viverra odio. Duis in sem justo. Aliquam egestas elit eget finibus sollicitudin. Phasellus congue nisl magna, consequat suscipit sapien sollicitudin tincidunt. Etiam viverra aliquet erat, id rutrum purus tristique in. Praesent in ligula pellentesque, viverra lorem nec, vestibulum ex. Praesent eu nisl efficitur, luctus urna nec, suscipit dolor. Morbi at leo iaculis, congue ligula eu, porta nisi. Phasellus faucibus ex quis dui ultricies, vehicula placerat sem auctor. Nam bibendum cursus dui sit amet mollis. In ullamcorper mi odio, vitae posuere felis tristique non. Integer id hendrerit risus." );
    _lorem.append_val( "Aliquam massa sapien, fringilla nec magna vel, gravida iaculis diam. Proin quis eros nibh. Nullam gravida molestie felis, at venenatis neque egestas eget. Sed sollicitudin, sem eget placerat bibendum, mauris leo malesuada nisi, vel varius ante enim sed justo. Donec consectetur porta accumsan. Pellentesque faucibus a massa ac bibendum. Duis maximus mauris vel neque rutrum, vitae volutpat enim lacinia. Praesent aliquam ante justo. Nullam eget risus metus. Aenean consectetur felis in erat blandit tincidunt. Vestibulum quis urna vehicula, lacinia ante eu, bibendum nisi." );
    _lorem.append_val( "Nulla dictum congue dignissim. Donec commodo risus et bibendum dapibus. Cras a faucibus erat, nec rhoncus felis. Quisque nisi risus, faucibus maximus venenatis nec, dignissim a dui. Vivamus condimentum ut urna maximus accumsan. Mauris in nibh vel ante dictum ullamcorper sed in nulla. Nam finibus metus nulla, et commodo ipsum congue elementum. Duis pellentesque, felis quis auctor fermentum, purus erat finibus leo, venenatis facilisis risus nisl in leo. Nullam feugiat auctor nisi." );
    _lorem.append_val( "Nullam vehicula consectetur est, vitae interdum libero pulvinar id. Duis dolor lacus, varius eu purus vel, porta ultrices ante. Nulla non vehicula odio. Proin maximus vehicula nibh. Praesent interdum non dolor at malesuada. In sed purus nunc. In tincidunt arcu sed quam molestie commodo. Curabitur sagittis eros vel felis vehicula semper." );
    _lorem.append_val( "Curabitur suscipit vehicula tellus, nec suscipit lectus feugiat et. Curabitur quis tempor purus. Praesent varius, tellus et aliquet porta, enim justo aliquet ipsum, ut eleifend dui orci eget erat. Mauris ipsum ante, tempus sed porttitor quis, bibendum venenatis metus. In feugiat, tellus quis malesuada dapibus, elit velit hendrerit velit, eu molestie dui arcu sit amet ligula. Suspendisse et malesuada purus, id tempus neque. Cras consectetur urna quis consectetur vestibulum." );
    _lorem.append_val( "Nulla facilisi. Curabitur consectetur tortor a urna convallis cursus. Nam felis ligula, cursus sed lorem sed, maximus tempus urna. Proin vitae vulputate urna, non pretium erat. Sed porta eros non urna facilisis tempus. Cras sed dolor eget dui egestas laoreet. Integer lacinia pellentesque justo, maximus eleifend quam porttitor in. Praesent sollicitudin et diam sed aliquam. Praesent ac est volutpat, molestie nisi at, condimentum ipsum. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos." );
    _lorem.append_val( "Proin sed scelerisque tortor. Curabitur semper congue orci id fermentum. Vestibulum sollicitudin erat nulla. Pellentesque ullamcorper lorem justo, quis finibus risus semper at. Nunc egestas est bibendum enim viverra eleifend. Donec et sodales nisl, non pulvinar lacus. Maecenas vestibulum posuere nunc et sollicitudin. In lorem augue, interdum a laoreet et, scelerisque vitae leo. Nulla feugiat ex dui, quis efficitur augue mollis nec. Praesent tincidunt tempor dolor at aliquam." );
    _lorem.append_val( "Integer finibus ornare leo ut mollis. In hac habitasse platea dictumst. Nulla nec ante tristique, molestie velit id, euismod velit. Ut vel finibus lectus, id ullamcorper mi. Curabitur ut orci egestas, imperdiet ligula id, posuere erat. Donec eget augue a sem tincidunt lacinia blandit eget ipsum. Vivamus fringilla, ligula sed iaculis sollicitudin, augue massa rutrum nibh, quis scelerisque diam neque sodales dui. Vestibulum congue maximus rutrum. Sed ligula augue, fermentum ac posuere id, congue nec purus. Morbi tempor elementum velit, ac ornare velit suscipit eu. Aenean luctus posuere auctor. Phasellus vestibulum, enim vitae hendrerit hendrerit, metus nibh faucibus massa, at pulvinar dolor massa eget orci. Sed non est porta, lacinia urna nec, tristique turpis." );
    _lorem.append_val( "Nulla sed dignissim neque. Nullam congue urna sit amet elit sollicitudin porttitor. Proin condimentum turpis et fringilla suscipit. Nullam convallis neque in tortor lacinia, et convallis risus convallis. Donec egestas risus ut nisl tristique mollis. Curabitur ultrices sed massa vitae facilisis. Aenean suscipit dui vehicula nisl sodales gravida." );
    _lorem.append_val( "Mauris lobortis sapien eu bibendum facilisis. Pellentesque vel tortor et lectus aliquet sollicitudin in ac urna. Duis ac ipsum nec est molestie eleifend. Etiam aliquam, neque vel tincidunt ornare, sem ipsum vulputate lacus, id ultricies est arcu finibus lacus. In malesuada nisl et ipsum interdum, non efficitur ligula luctus. Maecenas et malesuada nibh. Integer a eros libero. Aliquam ut cursus nisl, id laoreet dolor. Sed volutpat turpis sed erat vestibulum dignissim. Curabitur diam sem, viverra non consequat eu, facilisis eu enim." );
  }

  protected override string get_label0() {
    return( _( "Insert Lorem Ipsum" ) );
  }

  public override TextFunction copy() {
    var fn = new InsertLoremIpsum();
    fn._paragraphs = _paragraphs;
    return( fn );
  }

  private string get_lorem_ipsum() {
    var rand = new Rand();
    var rn   = rand.int_range( 0, ((int)_lorem.length - 1) );
    var str  = "";
    for( int i=0; i<_paragraphs; i++ ) {
      str += _lorem.index( (rn + i) % _lorem.length ) + "\n\n";
    }
    return( str );
  }

  /* Perform the transformation */
  public override string transform_text( string original, int cursor_pos ) {
    var lorem  = get_lorem_ipsum();
    var prefix = (cursor_pos > 0) ? original.slice( 0, cursor_pos ) : "";
    var suffix = (cursor_pos != -1) ? original.slice( cursor_pos, original.length ) : "";
    stdout.printf( "%s%s%s\n", prefix, lorem, suffix );
    return( prefix + lorem + suffix );
  }

  public override bool settings_available() {
    return( true );
  }

  /* Populates the given popover with the settings */
  public override void add_settings( Grid grid ) {

    add_range_setting( grid, 0, _( "Paragraphs" ), 1, 20, 1, _paragraphs, (value) => {
      _paragraphs = value;
    });

  }

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "paragraphs", _paragraphs.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node, TextFunctions functions ) {
    base.load( node, functions );
    var p = node->get_prop( "paragraphs" );
    if( p != null ) {
      _paragraphs = int.parse( p );
    }
  }

}

