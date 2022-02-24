import { Component, OnInit } from '@angular/core';
import { routerTransition } from '../../router.animations';
import { DataService } from '../data.service';
import { DataTableDirective } from 'angular-datatables';
import { Subject } from 'rxjs';
import {ExcelService} from '../../excel.service';
@Component({
  selector: 'app-upload',
  templateUrl: './upload.component.html',
  styleUrls: ['./upload.component.scss'],
  animations: [routerTransition()]
})
export class UploadComponent implements OnInit {

  constructor(  public dataservice:DataService,
    public excelService:ExcelService) { }

  ngOnInit() {
  }

}
