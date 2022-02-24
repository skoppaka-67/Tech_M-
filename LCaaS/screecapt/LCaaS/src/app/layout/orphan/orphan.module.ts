import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { OrphanRoutingModule } from './orphan-routing.module';
import { OrphanComponent } from './orphan.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, OrphanRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [OrphanComponent]
})
export class OrphanModule {}
