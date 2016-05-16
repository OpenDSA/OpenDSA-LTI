# import the wb module
from wb import *
# import the grt module
import grt
# import the mforms module for GUI stuff
import mforms



# define this Python module as a GRT module
ModuleInfo = DefineModule(name= "AutoRelationshipUtils", author= "Oracle Corp.", version="1.0")


def get_fk_candidate_list(schema, fk_name_format, match_types=False):
    candidate_list = []
    possible_fks = {}
    # create the list of possible foreign keys out of the list of tables
    for table in schema.tables:
        if table.primaryKey and len(table.primaryKey.columns) == 1: # composite FKs not supported
            format_args = {'table':table.name, 'pk':table.primaryKey.columns[0].name}
            fkname = fk_name_format % format_args
            possible_fks[fkname] = table

    # go through all tables in schema again, this time to find columns that seem to be a fk
    for table in schema.tables:
        for column in table.columns:
            if possible_fks.has_key(column.name):
                ref_table = possible_fks[column.name]
                ref_column = ref_table.primaryKey.columns[0].referencedColumn
                if ref_column == column:
                    continue
                if match_types and ref_column.formattedType != column.formattedType:
                    continue

                candidate_list.append((table, column, ref_table, ref_column))
    return candidate_list


class RelationshipCreator(mforms.Form):
  def __init__(self, catalog):
    mforms.Form.__init__(self, None, mforms.FormNone)

    self.catalog = catalog

    self.set_title("Create Relationships for Tables")

    box = mforms.newBox(False)
    self.set_content(box)
    box.set_padding(12)
    box.set_spacing(12)

    label = mforms.newLabel(
"""This will automatically create foreign keys for tables that match
a certain column naming pattern, allowing you to visualize relationships 
between MyISAM tables.

To use, fill the Column Pattern field with the naming convention used for
columns that are meant to be used as foreign keys. The %(table)s and %(pk)s
variable names will be substituted with the referenced table values.""")
    box.add(label, False, True)

    hbox = mforms.newBox(True)
    hbox.set_spacing(12)
    box.add(hbox, False, True)

    label = mforms.newLabel("Column Pattern:")
    hbox.add(label, False, True)
    self.pattern = mforms.newTextEntry()
    hbox.add(self.pattern, True, True)
    self.matchType = mforms.newCheckBox()
    self.matchType.set_text("Match column types")
    hbox.add(self.matchType, False, True)
    self.matchType.set_active(True)
    search = mforms.newButton()
    search.set_text("Preview Matches")
    search.add_clicked_callback(self.findMatches)
    hbox.add(search, False, True)

    self.pattern.set_value("%(table)s_id")

    self.candidateTree = mforms.newTreeView(mforms.TreeShowHeader)
    self.candidateTree.add_column(mforms.StringColumnType, "From Table", 100, False)
    self.candidateTree.add_column(mforms.StringColumnType, "Column", 100, False)
    self.candidateTree.add_column(mforms.StringColumnType, "Type", 100, False)
    self.candidateTree.add_column(mforms.StringColumnType, "To Table", 100, False)
    self.candidateTree.add_column(mforms.StringColumnType, "Column", 100, False)
    self.candidateTree.add_column(mforms.StringColumnType, "Type", 100, False)
    self.candidateTree.end_columns()
    box.add(self.candidateTree, True, True)

    hbox = mforms.newBox(True)
    hbox.set_spacing(12)
    self.matchCount = mforms.newLabel("")
    hbox.add(self.matchCount, False, True)
    self.cancelButton = mforms.newButton()
    self.cancelButton.set_text("Cancel")
    hbox.add_end(self.cancelButton, False, True)
    self.okButton = mforms.newButton()
    self.okButton.set_text("Create FKs")
    hbox.add_end(self.okButton, False, True)
    self.okButton.add_clicked_callback(self.createFKs)
    box.add(hbox, False, True)

    self.set_size(700, 600)

  def findMatches(self):
    candidates = []
    for schema in self.catalog.schemata:
      candidates += get_fk_candidate_list(schema, self.pattern.get_string_value(), self.matchType.get_active())
    self.candidateTree.clear_rows()
    for table, column, ref_table, ref_column in candidates:
      row = self.candidateTree.add_row()
      self.candidateTree.set_string(row, 0, table.name)
      self.candidateTree.set_string(row, 1, column.name)
      self.candidateTree.set_string(row, 2, column.formattedType)
      self.candidateTree.set_string(row, 3, ref_table.name)
      self.candidateTree.set_string(row, 4, ref_column.name)
      self.candidateTree.set_string(row, 5, ref_column.formattedType)
    self.matchCount.set_text("%i matches found" % len(candidates))


  def createFKs(self):
    candidates = []
    for schema in self.catalog.schemata:
      candidates += get_fk_candidate_list(schema, self.pattern.get_string_value())

    for table, column, ref_table, ref_column in candidates:
      fk = table.createForeignKey(ref_column.name+"_fk")
      fk.referencedTable = ref_table
      fk.columns.append(column)
      fk.referencedColumns.append(ref_column)


  def run(self):
    self.run_modal(self.okButton, self.cancelButton)



@ModuleInfo.plugin("wb.catalog.util.autoCreateRelationships", caption= "Create Relationships from Columns", input= [wbinputs.currentCatalog()], pluginMenu= "Catalog", type="standalone")
@ModuleInfo.export(grt.INT, grt.classes.db_Catalog)
def autoCreateRelationships(catalog):
  form = RelationshipCreator(catalog)
  form.run()
  return 0

