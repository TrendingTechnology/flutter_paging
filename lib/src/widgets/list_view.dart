import 'dart:developer' as developer;

import 'package:fl_paging/src/datasource/data_source.dart';
import 'package:fl_paging/src/widgets/base_widget.dart';
import 'package:fl_paging/src/widgets/default/paging_default_loading.dart';
import 'package:fl_paging/src/widgets/paging_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;

import 'default/load_more_widget.dart';

class ListView<T> extends BaseWidget<T> {
  final widgets.EdgeInsets padding;
  final WidgetBuilder separatorBuilder;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController controller;
  final bool primary;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double cacheExtent;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  ListView(
      {Key key,
      this.padding,
      this.separatorBuilder,
      this.scrollDirection = Axis.vertical,
      this.reverse = false,
      this.controller,
      this.primary,
      this.physics,
      this.shrinkWrap = false,
      this.addRepaintBoundaries = true,
      this.addAutomaticKeepAlives = true,
      this.addSemanticIndexes = true,
      this.cacheExtent,
      this.dragStartBehavior = DragStartBehavior.start,
      this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
      ValueWidgetBuilder<T> itemBuilder,
      DataSource<T> pageDataSource})
      : super(
            itemBuilder: itemBuilder, pageDataSource: pageDataSource, key: key);
  @override
  _ListViewState<T> createState() => _ListViewState<T>();
}

class _ListViewState<T> extends State<ListView<T>> {
  static const TAG = 'ListView';
  PagingState<T> _pagingState = PagingState.loading();

  void emit(PagingState<T> state) {
    setState(() {
      _pagingState = state;
    });
  }

  Future _loadPage({bool isRefresh = false}) async {
    developer.log('_loadPage [isRefresh]: [$isRefresh]', name: TAG);
    if (isRefresh == true) {
      try {
        emit(PagingState<T>(
            await widget.pageDataSource.loadPage(isRefresh: isRefresh),
            false, widget.pageDataSource.isEndList));
      } catch (error) {
        emit(PagingState.error(error));
      }
    } else {
      if (_pagingState is PagingStateLoading<T>) {
        widget.pageDataSource.loadPage().then((value) {
          emit(PagingState<T>(value, false, widget.pageDataSource.isEndList));
        }, onError: (error) {
          emit(PagingState.error(error));
        });
      } else {
        widget.pageDataSource.loadPage().then((value) {
          final oldState = (_pagingState as PagingStateData<T>);
            if (value.length == 0) {
              emit(oldState.copyWith
                  .call(isLoadMore: false, isEndList: true));
            } else {
              emit(oldState.copyWith.call(
                  isLoadMore: false,
                  isEndList: widget.pageDataSource.isEndList,
                  datas: oldState.datas..addAll(value)));
            }
        }, onError: (error) {
          emit(PagingState.error(error));
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return _pagingState.when((datas, isLoadMore, isEndList) {
      if (datas.length == 0) {
        return widget.emptyBuilder(context);
      } else {
        //region child
        Widget child = widgets.ListView.separated(
          padding: widget.padding,
          cacheExtent: widget.cacheExtent,
          scrollDirection: widget.scrollDirection,
          reverse: widget.reverse,
          primary: widget.primary,
          physics: widget.physics,
          controller: widget.controller,
          addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
          addRepaintBoundaries: widget.addRepaintBoundaries,
          addSemanticIndexes: widget.addSemanticIndexes,
          dragStartBehavior: widget.dragStartBehavior,
          shrinkWrap: widget.shrinkWrap,
          keyboardDismissBehavior: widget.keyboardDismissBehavior,
          separatorBuilder: (context, index) {
            return widget.separatorBuilder != null ? widget.separatorBuilder(context) : const SizedBox(height: 16,);
          },
          itemBuilder: (context, index) {
            return index == datas.length ? LoadMoreWidget() : widget.itemBuilder(context, datas[index], null);
          },
          itemCount: !isEndList ? datas.length + 1 : datas.length,
        );
        //endregion
        return RefreshIndicator(
          child: NotificationListener<ScrollNotification>(
            child: child,
            onNotification: (notification) {
              if (!isEndList && notification is ScrollEndNotification
                  && (notification.metrics.pixels == notification.metrics.maxScrollExtent)) {
                  if (_pagingState is PagingStateData<T> && (!isEndList && !isLoadMore)) {
                    _loadPage();
                    emit((_pagingState as PagingStateData<T>).copyWith(isLoadMore: true));
                  }
              }
              return false;
            },
          ),
          onRefresh: () {
            return _loadPage(isRefresh: true);
          },
        );
      }
    },
    loading: () => (widget.loadingBuilder != null) ? widget.loadingBuilder(context) : PagingDefaultLoading(),
    error: (error)  => widget.errorBuilder != null ?  widget.errorBuilder(context, error) :  ErrorWidget(error)
    );
  }
}
