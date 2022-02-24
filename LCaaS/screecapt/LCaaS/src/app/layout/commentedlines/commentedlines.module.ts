import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BrowserModule } from '@angular/platform-browser';
import {DataTablesModule } from 'angular-datatables';

import { CommentedLinesRoutingModule } from './commentedlines-routing.module';
import { CommentedLinesComponent } from './commentedlines.component';
import { PageHeaderModule } from '../../shared';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';


@NgModule({
    imports: [CommonModule, CommentedLinesRoutingModule, PageHeaderModule,DataTablesModule, NgbModule],
    declarations: [CommentedLinesComponent]
})
export class CommentedLinesModule {}
